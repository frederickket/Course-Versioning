/**
 * @author      WDCi (XW)
 * @date        Mar 2025
 * @group       Test
 * @description Test class for IPA_StudyIntakeRollUp_EXE
 * @changehistory
 * ISS-002090 12-03-2025 XW - new class
 * ISS-002415 24-04-2025 XW - test methods are recreated
 * ISS-002526 15-06-2025 XW - added test cases for study intake group parent
 */

@IsTest
public inherited sharing class IPA_StudyIntakeRollUp_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    static final String KEY_SPG = 'BACBIS';
    static final String KEY_CONTACT = 'sandydoe@redu.example';
    static final String KEY_PYINTAKE = 'SYDNEY_BACBIS_PYINTAKE';
    static final String KEY_CYINTAKE = 'SYDNEY_BACBIS_CYINTAKE';
    static final String KEY_NYINTAKE = 'SYDNEY_BACBIS_NYINTAKE';
    static final String KEY_SIGSTANDARD = KEY_CYINTAKE + '_Standard';
    static final String KEY_SIGDISABLED = KEY_CYINTAKE + '_Disabled';
    static final Integer STUDY_INTAKE_CAPACITY = 5;

    static final String APPLICATION_STATUS_REVIEWING_AWAITING_DOCS = 'Reviewing - Awaiting Documentation';

    static reduivy__Study_Program__c spgRecord = null;

    static final String FIELD_BOOKED_PLACES = 'reduivy__Booked_Places__c';
    static final String FIELD_SUBMITTED_APPLICATIONS = 'reduivy__Submitted_Applications__c';
    static final String FIELD_APPROVED_APPLICATIONS = 'reduivy__Approved_Applications__c';
    static final String FIELD_ACCEPTED_APPLICATIONS = 'reduivy__Accepted_Applications__c';
    static final String FIELD_REJECTED_APPLICATIONS = 'reduivy__Rejected_Applications__c';
    static final String FIELD_REVIEWING_APPLICATIONS = 'reduivy__Reviewing_Applications__c';


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
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});

            testFactory.initMasterData(SPL_Helper.getApiName());
            testFactory.initOfferingData(SIG_Helper.getApiName());

            Id sitPyId = testFactory.studyIntakes.get(KEY_PYINTAKE).Id;
            Id sitCyId = testFactory.studyIntakes.get(KEY_CYINTAKE).Id;
            Id sitNyId = testFactory.studyIntakes.get(KEY_NYINTAKE).Id;

            update new List<reduivy__Study_Intake__c> {
                new reduivy__Study_Intake__c(Id = sitPyId, reduivy__Capacity__c = STUDY_INTAKE_CAPACITY),
                new reduivy__Study_Intake__c(Id = sitCyId, reduivy__Capacity__c = STUDY_INTAKE_CAPACITY),
                new reduivy__Study_Intake__c(Id = sitNyId, reduivy__Capacity__c = STUDY_INTAKE_CAPACITY)
            };

            Id sigStandardId = testFactory.studyIntakeGroups.get(KEY_SIGSTANDARD).Id;
            Id sigDisabledId = testFactory.studyIntakeGroups.get(KEY_SIGDISABLED).Id;

            update new List<reduivy__Study_Intake_Group__c> {
                new reduivy__Study_Intake_Group__c(Id = sigStandardId, reduivy__Capacity__c = STUDY_INTAKE_CAPACITY),
                new reduivy__Study_Intake_Group__c(Id = sigDisabledId, reduivy__Capacity__c = STUDY_INTAKE_CAPACITY)
            };

            
            
            testFactory.initFacultyData(USR_Helper.getApiName(), true);
            testFactory.initStudentData(USR_Helper.getApiName(), true);
            
            REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
		}

    }

    /**
     * @description test as admin, create approved ipa
     */
    @IsTest
    static void testAsAdmin_CreateIpa_Approved() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake__c sitBefore = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBefore), sitApplicationFieldsNotEmptyErrorMsg(sitBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_APPROVED, sitBefore.Id, con.Id);
            insert ipa;
            
            reduivy__Study_Intake__c sitAfter = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(1, sitAfter.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sitAfter.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Excepted: 0; Actual: ' + sitAfter.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Excepted: 0; Actual: ' + sitAfter.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Excepted: 0; Actual: ' + sitAfter.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Excepted: 0; Actual: ' + sitAfter.get(FIELD_BOOKED_PLACES));

        }
        
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description test as admin, create offer ipa
     */
    @IsTest
    static void testAsAdmin_CreateIpa_Offer() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake__c sitBefore = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBefore), sitApplicationFieldsNotEmptyErrorMsg(sitBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_OFFER, sitBefore.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake__c sitAfter = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(1, sitAfter.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sitAfter.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Excepted: 0; Actual: ' + sitAfter.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Excepted: 0; Actual: ' + sitAfter.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Excepted: 0; Actual: ' + sitAfter.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Excepted: 0; Actual: ' + sitAfter.get(FIELD_BOOKED_PLACES));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description test as admin, create offer accepted ipa
     */
    @IsTest
    static void testAsAdmin_CreateIpa_OfferAccepted() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake__c sitBefore = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBefore), sitApplicationFieldsNotEmptyErrorMsg(sitBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED, sitBefore.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake__c sitAfter = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(1, sitAfter.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sitAfter.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.areEqual(1, sitAfter.reduivy__Accepted_Applications__c, 'Wrong Accepted Applications!');
            System.Assert.areEqual(1, sitAfter.reduivy__Booked_Places__c, 'Wrong Booked Places!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Excepted: 0; Actual: ' + sitAfter.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Excepted: 0; Actual: ' + sitAfter.get(FIELD_REVIEWING_APPLICATIONS));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description test as admin, create offer declined ipa
     */
    @IsTest
    static void testAsAdmin_CreateIpa_OfferDeclined() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake__c sitBefore = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBefore), sitApplicationFieldsNotEmptyErrorMsg(sitBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_OFFER_DECLINED, sitBefore.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake__c sitAfter = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(1, sitAfter.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sitAfter.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Excepted: 0; Actual: ' + sitAfter.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Excepted: 0; Actual: ' + sitAfter.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Excepted: 0; Actual: ' + sitAfter.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Excepted: 0; Actual: ' + sitAfter.get(FIELD_BOOKED_PLACES));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description test as admin, create rejected ipa
     */
    @IsTest
    static void testAsAdmin_CreateIpa_Rejected() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake__c sitBefore = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBefore), sitApplicationFieldsNotEmptyErrorMsg(sitBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REJECTED, sitBefore.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake__c sitAfter = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(1, sitAfter.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sitAfter.reduivy__Rejected_Applications__c, 'Wrong Rejected Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Excepted: 0; Actual: ' + sitAfter.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications! Excepted: 0; Actual: ' + sitAfter.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Excepted: 0; Actual: ' + sitAfter.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Excepted: 0; Actual: ' + sitAfter.get(FIELD_BOOKED_PLACES));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description test as admin, create reviewing ipa
     */
    @IsTest
    static void testAsAdmin_CreateIpa_Reviewing() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake__c sitBefore = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBefore), sitApplicationFieldsNotEmptyErrorMsg(sitBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REVIEWING, sitBefore.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake__c sitAfter = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(1, sitAfter.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sitAfter.reduivy__Reviewing_Applications__c, 'Wrong Reviewing Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Excepted: 0; Actual: ' + sitAfter.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Excepted: 0; Actual: ' + sitAfter.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications! Excepted: 0; Actual: ' + sitAfter.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Excepted: 0; Actual: ' + sitAfter.get(FIELD_BOOKED_PLACES));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description test as admin, create reviewing awaiting docs ipa
     */
    @IsTest
    static void testAsAdmin_CreateIpa_ReviewingAwaitingDocs() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake__c sitBefore = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBefore), sitApplicationFieldsNotEmptyErrorMsg(sitBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(APPLICATION_STATUS_REVIEWING_AWAITING_DOCS, sitBefore.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake__c sitAfter = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(1, sitAfter.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sitAfter.reduivy__Reviewing_Applications__c, 'Wrong Reviewing Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Excepted: 0; Actual: ' + sitAfter.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Excepted: 0; Actual: ' + sitAfter.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications! Excepted: 0; Actual: ' + sitAfter.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Excepted: 0; Actual: ' + sitAfter.get(FIELD_BOOKED_PLACES));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description test as admin, create submitted ipa
     */
    @IsTest
    static void testAsAdmin_CreateIpa_Submitted() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake__c sitBefore = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBefore), sitApplicationFieldsNotEmptyErrorMsg(sitBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sitBefore.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake__c sitAfter = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(1, sitAfter.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications! Excepted: 0; Actual: ' + sitAfter.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Excepted: 0; Actual: ' + sitAfter.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Excepted: 0; Actual: ' + sitAfter.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Excepted: 0; Actual: ' + sitAfter.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Excepted: 0; Actual: ' + sitAfter.get(FIELD_BOOKED_PLACES));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description test as admin, create draft ipa
     */
    @IsTest
    static void testAsAdmin_CreateIpa_Draft() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake__c sitBefore = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBefore), sitApplicationFieldsNotEmptyErrorMsg(sitBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_DRAFT, sitBefore.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake__c sitAfter = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitAfter), sitApplicationFieldsNotEmptyErrorMsg(sitAfter));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description test as admin, create cancelled ipa
     */
    @IsTest
    static void testAsAdmin_CreateIpa_Cancelled() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake__c sitBefore = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBefore), sitApplicationFieldsNotEmptyErrorMsg(sitBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_CANCELLED, sitBefore.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake__c sitAfter = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitAfter), sitApplicationFieldsNotEmptyErrorMsg(sitAfter));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testAsAdmin to update ipa from draft to submitted
     */
    @IsTest
    static void testAsAdmin_UpdateIpa_DraftToSubmitted() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake__c sitBeforeInsertIpa = querySit(KEY_CYINTAKE);
            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_DRAFT, sitBeforeInsertIpa.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake__c sitBeforeUpdateIpa = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBeforeUpdateIpa), sitApplicationFieldsNotEmptyErrorMsg(sitBeforeUpdateIpa));

            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_SUBMITTED;
            update ipa;

            reduivy__Study_Intake__c sitAfterUpdateIpa = querySit(KEY_CYINTAKE);

            System.Assert.areEqual(1, sitAfterUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications! Excepted: 0; Actual: ' + sitAfterUpdateIpa.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Excepted: 0; Actual: ' + sitAfterUpdateIpa.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Excepted: 0; Actual: ' + sitAfterUpdateIpa.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Excepted: 0; Actual: ' + sitAfterUpdateIpa.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Excepted: 0; Actual: ' + sitAfterUpdateIpa.get(FIELD_BOOKED_PLACES));
            
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    @IsTest
    static void testAsAdmin_UpdateIpa_SubmittedToReviewing() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake__c sitBeforeInsertIpa = querySit(KEY_CYINTAKE);
            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sitBeforeInsertIpa.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake__c sitBeforeUpdateIpa = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(1, sitBeforeUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places before update!');

            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING;
            update ipa;

            reduivy__Study_Intake__c sitAfterUpdateIpa = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(1, sitAfterUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sitAfterUpdateIpa.reduivy__Reviewing_Applications__c, 'Wrong Reviewing Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places!');
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    @IsTest
    static void testAsAdmin_UpdateIpa_ReviewingToApproved() {
        User ADMIN_USER = testFactory.getReduAdminUser();
    
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake__c sitBeforeInsertIpa = querySit(KEY_CYINTAKE);
            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REVIEWING, sitBeforeInsertIpa.Id, con.Id);
            insert ipa;
    
            reduivy__Study_Intake__c sitBeforeUpdateIpa = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(1, sitBeforeUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before update!');
            System.Assert.areEqual(1, sitBeforeUpdateIpa.reduivy__Reviewing_Applications__c, 'Wrong Reviewing Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places before update!');
    
            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;
            update ipa;
    
            reduivy__Study_Intake__c sitAfterUpdateIpa = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(1, sitAfterUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sitAfterUpdateIpa.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places!');
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }
    
    @IsTest
    static void testAsAdmin_UpdateIpa_ApprovedToOffer() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake__c sitBeforeInsertIpa = querySit(KEY_CYINTAKE);
            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_APPROVED, sitBeforeInsertIpa.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake__c sitBeforeUpdateIpa = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(1, sitBeforeUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before update!');
            System.Assert.areEqual(1, sitBeforeUpdateIpa.reduivy__Approved_Applications__c, 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places before update!');

            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER;
            update ipa;

            reduivy__Study_Intake__c sitAfterUpdateIpa = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(1, sitAfterUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sitAfterUpdateIpa.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places!');
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    @IsTest
    static void testAsAdmin_UpdateIpa_OfferToAccepted() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake__c sitBeforeInsertIpa = querySit(KEY_CYINTAKE);
            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_OFFER, sitBeforeInsertIpa.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake__c sitBeforeUpdateIpa = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(1, sitBeforeUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before update!');
            System.Assert.areEqual(1, sitBeforeUpdateIpa.reduivy__Approved_Applications__c, 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places before update!');

            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;
            update ipa;

            reduivy__Study_Intake__c sitAfterUpdateIpa = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(1, sitAfterUpdateIpa.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.areEqual(1, sitAfterUpdateIpa.reduivy__Accepted_Applications__c, 'Wrong Accepted Applications!');
            System.Assert.areEqual(1, sitAfterUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sitAfterUpdateIpa.reduivy__Booked_Places__c, 'Wrong Booked Places!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications!');

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    @IsTest
    static void testAsAdmin_UpdateIpa_OfferToDeclined() {
        User ADMIN_USER = testFactory.getReduAdminUser();
    
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake__c sitBeforeInsertIpa = querySit(KEY_CYINTAKE);
            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_OFFER, sitBeforeInsertIpa.Id, con.Id);
            insert ipa;
    
            reduivy__Study_Intake__c sitBeforeUpdateIpa = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(1, sitBeforeUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before update!');
            System.Assert.areEqual(1, sitBeforeUpdateIpa.reduivy__Approved_Applications__c, 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places before update!');
    
            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_DECLINED;
            update ipa;
    
            reduivy__Study_Intake__c sitAfterUpdateIpa = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(1, sitAfterUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sitBeforeUpdateIpa.reduivy__Approved_Applications__c, 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places!');
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }
    
    @IsTest
    static void testAsAdmin_UpdateIpa_ReviewingToRejected() {
        User ADMIN_USER = testFactory.getReduAdminUser();
    
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake__c sitBeforeInsertIpa = querySit(KEY_CYINTAKE);
            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REVIEWING, sitBeforeInsertIpa.Id, con.Id);
            insert ipa;
    
            reduivy__Study_Intake__c sitBeforeUpdateIpa = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(1, sitBeforeUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before update!');
            System.Assert.areEqual(1, sitBeforeUpdateIpa.reduivy__Reviewing_Applications__c, 'Wrong Reviewing Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places before update!');
    
            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REJECTED;
            update ipa;
    
            reduivy__Study_Intake__c sitAfterUpdateIpa = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(1, sitAfterUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sitAfterUpdateIpa.reduivy__Rejected_Applications__c, 'Wrong Rejected Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places!');
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    @IsTest
    static void testAsAdmin_UpdateIpa_SubmittedToCancelled() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake__c sitBeforeInsertIpa = querySit(KEY_CYINTAKE);
            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sitBeforeInsertIpa.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake__c sitBeforeUpdateIpa = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(1, sitBeforeUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places before update!');

            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_CANCELLED;
            update ipa;

            reduivy__Study_Intake__c sitAfterUpdateIpa = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitAfterUpdateIpa), sitApplicationFieldsNotEmptyErrorMsg(sitAfterUpdateIpa));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testAsAdmin to delete and undelete IPA with status Submitted
     */
    @IsTest
    static void testAsAdmin_DeleteUndeleteIpa_Submitted() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake__c sitBeforeInsert = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBeforeInsert), sitApplicationFieldsNotEmptyErrorMsg(sitBeforeInsert));

            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>();

            for (Integer i = 0; i < 5; i++) {
                ipas.add(newIpaWithSit(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sitBeforeInsert.Id, con.Id));
            }
            insert ipas;

            reduivy__Study_Intake__c sitBeforeDelete = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(5, sitBeforeDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before delete!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeDelete, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications before delete! Expected: 0; Actual: ' + sitBeforeDelete.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before delete! Expected: 0; Actual: ' + sitBeforeDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before delete! Expected: 0; Actual: ' + sitBeforeDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places before delete! Expected: 0; Actual: ' + sitBeforeDelete.get(FIELD_BOOKED_PLACES));
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before delete! Expected: 0; Actual: ' + sitBeforeDelete.get(FIELD_REVIEWING_APPLICATIONS));

            delete ipas[0];

            reduivy__Study_Intake__c sitAfterDelete = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(4, sitAfterDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after delete!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterDelete, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications after delete! Expected: 0; Actual: ' + sitAfterDelete.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after delete! Expected: 0; Actual: ' + sitAfterDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after delete! Expected: 0; Actual: ' + sitAfterDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after delete! Expected: 0; Actual: ' + sitAfterDelete.get(FIELD_BOOKED_PLACES));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after delete! Expected: 0; Actual: ' + sitAfterDelete.get(FIELD_REVIEWING_APPLICATIONS));

            undelete ipas[0];

            reduivy__Study_Intake__c sitAfterUndelete = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(5, sitAfterUndelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after undelete!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUndelete, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications after undelete! Expected: 0; Actual: ' + sitAfterUndelete.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUndelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after undelete! Expected: 0; Actual: ' + sitAfterUndelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUndelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after undelete! Expected: 0; Actual: ' + sitAfterUndelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUndelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after undelete! Expected: 0; Actual: ' + sitAfterUndelete.get(FIELD_BOOKED_PLACES));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUndelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after undelete! Expected: 0; Actual: ' + sitAfterUndelete.get(FIELD_REVIEWING_APPLICATIONS));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }


    /**
     * @description testAsAdmin to delete and undelete IPA with status Draft
     */
    @IsTest
    static void testAsAdmin_DeleteUndeleteIpa_Draft() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake__c sitBeforeInsert = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBeforeInsert), sitApplicationFieldsNotEmptyErrorMsg(sitBeforeInsert));
            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>();

            for (Integer i = 0; i < 5; i++) {
                ipas.add(newIpaWithSit(IPA_Helper.APPLICATION_STATUS_DRAFT, sitBeforeInsert.Id, con.Id));
            }
            insert ipas;

            reduivy__Study_Intake__c sitBeforeDelete = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBeforeDelete), sitApplicationFieldsNotEmptyErrorMsg(sitBeforeDelete));

            delete ipas[0];
            reduivy__Study_Intake__c sitAfterDelete = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitAfterDelete), sitApplicationFieldsNotEmptyErrorMsg(sitAfterDelete));

            undelete ipas[0];
            reduivy__Study_Intake__c sitAfterUndelete = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitAfterUndelete), sitApplicationFieldsNotEmptyErrorMsg(sitAfterUndelete));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testAsAdmin to delete and undelete IPA with status Reviewing
     */
    @IsTest
    static void testAsAdmin_DeleteUndeleteIpa_Reviewing() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake__c sitBeforeInsert = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBeforeInsert), sitApplicationFieldsNotEmptyErrorMsg(sitBeforeInsert));

            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>();

            for (Integer i = 0; i < 5; i++) {
                ipas.add(newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REVIEWING, sitBeforeInsert.Id, con.Id));
            }
            insert ipas;

            reduivy__Study_Intake__c sitBeforeDelete = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(5, sitBeforeDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before delete!');
            System.Assert.areEqual(5, sitBeforeDelete.reduivy__Reviewing_Applications__c, 'Wrong Reviewing Applications before delete!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeDelete, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications before delete! Expected: 0; Actual: ' + sitBeforeDelete.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before delete! Expected: 0; Actual: ' + sitBeforeDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before delete! Expected: 0; Actual: ' + sitBeforeDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places before delete! Expected: 0; Actual: ' + sitBeforeDelete.get(FIELD_BOOKED_PLACES));

            delete ipas[0];
            reduivy__Study_Intake__c sitAfterDelete = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(4, sitAfterDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after delete!');
            System.Assert.areEqual(4, sitAfterDelete.reduivy__Reviewing_Applications__c, 'Wrong Reviewing Applications after delete!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterDelete, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications after delete! Expected: 0; Actual: ' + sitAfterDelete.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after delete! Expected: 0; Actual: ' + sitAfterDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after delete! Expected: 0; Actual: ' + sitAfterDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after delete! Expected: 0; Actual: ' + sitAfterDelete.get(FIELD_BOOKED_PLACES));

            undelete ipas[0];
            reduivy__Study_Intake__c sitAfterUndelete = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(5, sitAfterUndelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after undelete!');
            System.Assert.areEqual(5, sitAfterUndelete.reduivy__Reviewing_Applications__c, 'Wrong Reviewing Applications after undelete!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUndelete, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications after undelete! Expected: 0; Actual: ' + sitAfterUndelete.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUndelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after undelete! Expected: 0; Actual: ' + sitAfterUndelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUndelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after undelete! Expected: 0; Actual: ' + sitAfterUndelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUndelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after undelete! Expected: 0; Actual: ' + sitAfterUndelete.get(FIELD_BOOKED_PLACES));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testAsAdmin to delete and undelete IPA with status Approved
     */
    @IsTest
    static void testAsAdmin_DeleteUndeleteIpa_Approved() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake__c sitBeforeInsert = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBeforeInsert), sitApplicationFieldsNotEmptyErrorMsg(sitBeforeInsert));

            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>();

            for (Integer i = 0; i < 5; i++) {
                ipas.add(newIpaWithSit(IPA_Helper.APPLICATION_STATUS_APPROVED, sitBeforeInsert.Id, con.Id));
            }
            insert ipas;

            reduivy__Study_Intake__c sitBeforeDelete = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(5, sitBeforeDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before delete!');
            System.Assert.areEqual(5, sitBeforeDelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications before delete!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before delete! Expected: 0; Actual: ' + sitBeforeDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before delete! Expected: 0; Actual: ' + sitBeforeDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before delete! Expected: 0; Actual: ' + sitBeforeDelete.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places before delete! Expected: 0; Actual: ' + sitBeforeDelete.get(FIELD_BOOKED_PLACES));

            delete ipas[0];
            reduivy__Study_Intake__c sitAfterDelete = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(4, sitAfterDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after delete!');
            System.Assert.areEqual(4, sitAfterDelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications after delete!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after delete! Expected: 0; Actual: ' + sitAfterDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after delete! Expected: 0; Actual: ' + sitAfterDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after delete! Expected: 0; Actual: ' + sitAfterDelete.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after delete! Expected: 0; Actual: ' + sitAfterDelete.get(FIELD_BOOKED_PLACES));

            undelete ipas[0];
            reduivy__Study_Intake__c sitAfterUndelete = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(5, sitAfterUndelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after undelete!');
            System.Assert.areEqual(5, sitAfterUndelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications after undelete!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUndelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after undelete! Expected: 0; Actual: ' + sitAfterUndelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUndelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after undelete! Expected: 0; Actual: ' + sitAfterUndelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUndelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after undelete! Expected: 0; Actual: ' + sitAfterUndelete.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUndelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after undelete! Expected: 0; Actual: ' + sitAfterUndelete.get(FIELD_BOOKED_PLACES));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testAsAdmin to delete and undelete IPA with status Offer
     */
    @IsTest
    static void testAsAdmin_DeleteUndeleteIpa_Offer() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake__c sitBeforeInsert = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBeforeInsert), sitApplicationFieldsNotEmptyErrorMsg(sitBeforeInsert));

            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>();

            for (Integer i = 0; i < 5; i++) {
                ipas.add(newIpaWithSit(IPA_Helper.APPLICATION_STATUS_OFFER, sitBeforeInsert.Id, con.Id));
            }
            insert ipas;

            reduivy__Study_Intake__c sitBeforeDelete = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(5, sitBeforeDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before delete!');
            System.Assert.areEqual(5, sitBeforeDelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications before delete!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before delete! Expected: 0; Actual: ' + sitBeforeDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before delete! Expected: 0; Actual: ' + sitBeforeDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before delete! Expected: 0; Actual: ' + sitBeforeDelete.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places before delete! Expected: 0; Actual: ' + sitBeforeDelete.get(FIELD_BOOKED_PLACES));

            delete ipas[0];
            reduivy__Study_Intake__c sitAfterDelete = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(4, sitAfterDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after delete!');
            System.Assert.areEqual(4, sitAfterDelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications after delete!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after delete! Expected: 0; Actual: ' + sitAfterDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after delete! Expected: 0; Actual: ' + sitAfterDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after delete! Expected: 0; Actual: ' + sitAfterDelete.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after delete! Expected: 0; Actual: ' + sitAfterDelete.get(FIELD_BOOKED_PLACES));

            undelete ipas[0];
            reduivy__Study_Intake__c sitAfterUndelete = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(5, sitAfterUndelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after undelete!');
            System.Assert.areEqual(5, sitAfterUndelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications after undelete!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUndelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after undelete! Expected: 0; Actual: ' + sitAfterUndelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUndelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after undelete! Expected: 0; Actual: ' + sitAfterUndelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUndelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after undelete! Expected: 0; Actual: ' + sitAfterUndelete.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUndelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after undelete! Expected: 0; Actual: ' + sitAfterUndelete.get(FIELD_BOOKED_PLACES));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testAsAdmin to delete and undelete IPA with status Offer Accepted
     */
    @IsTest
    static void testAsAdmin_DeleteUndeleteIpa_OfferAccepted() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE', 'IPA_CreateEnrollment_EXE'});

        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake__c sitBeforeInsert = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBeforeInsert), sitApplicationFieldsNotEmptyErrorMsg(sitBeforeInsert));


            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>();

            for (Integer i = 0; i < 5; i++) {
                ipas.add(newIpaWithSit(IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED, sitBeforeInsert.Id, con.Id));
            }
            insert ipas;

            reduivy__Study_Intake__c sitBeforeDelete = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(5, sitBeforeDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before delete!');
            System.Assert.areEqual(5, sitBeforeDelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications before delete!');
            System.Assert.areEqual(5, sitBeforeDelete.reduivy__Accepted_Applications__c, 'Wrong Accepted Applications before delete!');
            System.Assert.areEqual(5, sitBeforeDelete.reduivy__Booked_Places__c, 'Wrong Booked Places before delete!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before delete! Expected: 0; Actual: ' + sitBeforeDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before delete! Expected: 0; Actual: ' + sitBeforeDelete.get(FIELD_REVIEWING_APPLICATIONS));

            delete ipas[0];
            reduivy__Study_Intake__c sitAfterDelete = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(4, sitAfterDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after delete!');
            System.Assert.areEqual(4, sitAfterDelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications after delete!');
            System.Assert.areEqual(4, sitAfterDelete.reduivy__Accepted_Applications__c, 'Wrong Accepted Applications after delete!');
            System.Assert.areEqual(4, sitAfterDelete.reduivy__Booked_Places__c, 'Wrong Booked Places after delete!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after delete! Expected: 0; Actual: ' + sitAfterDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after delete! Expected: 0; Actual: ' + sitAfterDelete.get(FIELD_REVIEWING_APPLICATIONS));

            undelete ipas[0];
            reduivy__Study_Intake__c sitAfterUndelete = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(5, sitAfterUndelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after undelete!');
            System.Assert.areEqual(5, sitAfterUndelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications after undelete!');
            System.Assert.areEqual(5, sitAfterUndelete.reduivy__Accepted_Applications__c, 'Wrong Accepted Applications after undelete!');
            System.Assert.areEqual(5, sitAfterUndelete.reduivy__Booked_Places__c, 'Wrong Booked Places after delete!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUndelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after undelete! Expected: 0; Actual: ' + sitAfterUndelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUndelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after undelete! Expected: 0; Actual: ' + sitAfterUndelete.get(FIELD_REVIEWING_APPLICATIONS));
        }

        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_CreateEnrollment_EXE'});
    }


    /**
     * @description testAsAdmin to delete and undelete IPA with status Offer Declined
     */
    @IsTest
    static void testAsAdmin_DeleteUndeleteIpa_OfferDeclined() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake__c sitBeforeInsert = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBeforeInsert), sitApplicationFieldsNotEmptyErrorMsg(sitBeforeInsert));

            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>();

            for (Integer i = 0; i < 5; i++) {
                ipas.add(newIpaWithSit(IPA_Helper.APPLICATION_STATUS_OFFER_DECLINED, sitBeforeInsert.Id, con.Id));
            }
            insert ipas;

            reduivy__Study_Intake__c sitBeforeDelete = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(5, sitBeforeDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before delete!');
            System.Assert.areEqual(5, sitBeforeDelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications before delete!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before delete! Expected: 0; Actual: ' + sitBeforeDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before delete! Expected: 0; Actual: ' + sitBeforeDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before delete! Expected: 0; Actual: ' + sitBeforeDelete.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places before delete! Expected: 0; Actual: ' + sitBeforeDelete.get(FIELD_BOOKED_PLACES));

            delete ipas[0];
            reduivy__Study_Intake__c sitAfterDelete = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(4, sitAfterDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after delete!');
            System.Assert.areEqual(4, sitAfterDelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications after delete!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after delete! Expected: 0; Actual: ' + sitAfterDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after delete! Expected: 0; Actual: ' + sitAfterDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after delete! Expected: 0; Actual: ' + sitAfterDelete.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after delete! Expected: 0; Actual: ' + sitAfterDelete.get(FIELD_BOOKED_PLACES));

            undelete ipas[0];
            reduivy__Study_Intake__c sitAfterUndelete = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(5, sitAfterUndelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after undelete!');
            System.Assert.areEqual(5, sitAfterUndelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications after undelete!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUndelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after undelete! Expected: 0; Actual: ' + sitAfterUndelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUndelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after undelete! Expected: 0; Actual: ' + sitAfterUndelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUndelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after undelete! Expected: 0; Actual: ' + sitAfterUndelete.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUndelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after undelete! Expected: 0; Actual: ' + sitAfterUndelete.get(FIELD_BOOKED_PLACES));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testAsAdmin to delete and undelete IPA with status Cancelled
     */
    @IsTest
    static void testAsAdmin_DeleteUndeleteIpa_Cancelled() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake__c sitBeforeInsert = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBeforeInsert), sitApplicationFieldsNotEmptyErrorMsg(sitBeforeInsert));

            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>();

            for (Integer i = 0; i < 5; i++) {
                ipas.add(newIpaWithSit(IPA_Helper.APPLICATION_STATUS_CANCELLED, sitBeforeInsert.Id, con.Id));
            }
            insert ipas;

            reduivy__Study_Intake__c sitBeforeDelete = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBeforeDelete), sitApplicationFieldsNotEmptyErrorMsg(sitBeforeDelete));

            delete ipas[0];
            reduivy__Study_Intake__c sitAfterDelete = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitAfterDelete), sitApplicationFieldsNotEmptyErrorMsg(sitAfterDelete));

            undelete ipas[0];
            reduivy__Study_Intake__c sitAfterUndelete = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitAfterUndelete), sitApplicationFieldsNotEmptyErrorMsg(sitAfterUndelete));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testAsAdmin to rollup to a nonexist field
     */
    @IsTest
    static void testAsAdmin_RollupFieldNotFound() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        IPA_Helper.isNegativeTests = true;
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake__c sitBefore = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBefore), sitApplicationFieldsNotEmptyErrorMsg(sitBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_DRAFT, sitBefore.Id, con.Id);
            try{
                insert ipa;
                System.Assert.fail('Should be failed if reduivy__Rollup_Field_API_Name__c is not found!');
            } catch (Exception exp) {
                System.Assert.isTrue(
                    exp.getMessage().contains(getSitInvalidFieldErrorMessage()), 
                    'Wrong error message! Expected: ' + getSitInvalidFieldErrorMessage() + '; Actual: ' + exp.getMessage()
                );
            }

            reduivy__Study_Intake__c sitAfter = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitAfter), sitApplicationFieldsNotEmptyErrorMsg(sitAfter));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testAsAdmin to rollup a nonexist ipa application status, no error should be thrown and will be simply ignored
     */
    @IsTest
    static void testAsAdmin_ApplicationStatusConfigNotFound() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        IPA_Helper.isNegativeTests = true;
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake__c sitBefore = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBefore), sitApplicationFieldsNotEmptyErrorMsg(sitBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_CANCELLED, sitBefore.Id, con.Id);
            insert ipa;


            reduivy__Study_Intake__c sitAfter = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitAfter), sitApplicationFieldsNotEmptyErrorMsg(sitAfter));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testAsAdmin to rollup to a date field
     */
    @IsTest
    static void testAsAdmin_RollupFieldIsNotNumber() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        IPA_Helper.isNegativeTests = true;
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake__c sitBefore = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBefore), sitApplicationFieldsNotEmptyErrorMsg(sitBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sitBefore.Id, con.Id);
            try{
                insert ipa;
                System.Assert.fail('Should be failed if reduivy__Rollup_Field_API_Name__c is not number field!');
            } catch (Exception exp) {
                System.Assert.isTrue(
                    exp.getMessage().contains(getSitInvalidFieldErrorMessage()), 
                    'Wrong error message! Expected: ' + getSitInvalidFieldErrorMessage() + '; Actual: ' + exp.getMessage()
                );
            }

            reduivy__Study_Intake__c sitAfter = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitAfter), sitApplicationFieldsNotEmptyErrorMsg(sitAfter));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testAsAdmin to rollup to a formula number field
     */
    @IsTest
    static void testAsAdmin_RollupFieldIsFormulaNumberField() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        IPA_Helper.isNegativeTests = true;
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake__c sitBefore = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBefore), sitApplicationFieldsNotEmptyErrorMsg(sitBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_APPROVED, sitBefore.Id, con.Id);
            try{
                insert ipa;
                System.Assert.fail('Should be failed if reduivy__Rollup_Field_API_Name__c is formula field!');
            } catch (Exception exp) {
                System.Assert.isTrue(
                    exp.getMessage().contains(getSitInvalidFieldErrorMessage()), 
                    'Wrong error message! Expected: ' + getSitInvalidFieldErrorMessage() + '; Actual: ' + exp.getMessage()
                );
            }

            reduivy__Study_Intake__c sitAfter = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitAfter), sitApplicationFieldsNotEmptyErrorMsg(sitAfter));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    @Istest
    static void testAsAdmin_CreateIpa_Approved_NoStudyIntake(){
        User ADMIN_USER = testFactory.getReduAdminUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake__c sitBefore = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBefore), sitApplicationFieldsNotEmptyErrorMsg(sitBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_APPROVED, null, con.Id);
            insert ipa;

            reduivy__Study_Intake__c sitAfter = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitAfter), sitApplicationFieldsNotEmptyErrorMsg(sitAfter));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testAsAdmin to update ipa from submitted to approved, linking Study Intake during update
     */
    @IsTest
    static void testAsAdmin_UpdateIpa_SubmittedToApproved_NoStudyIntakeToWithStudyIntake() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake__c sit = querySit(KEY_CYINTAKE);

            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_SUBMITTED, null, con.Id);
            insert ipa;

            reduivy__Study_Intake__c sitBeforeUpdate = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBeforeUpdate), sitApplicationFieldsNotEmptyErrorMsg(sitBeforeUpdate));

            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;
            ipa.reduivy__Study_Intake__c = sit.Id;
            update ipa;

            reduivy__Study_Intake__c sitAfterUpdate = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(1, sitAfterUpdate.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sitAfterUpdate.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdate, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Expected: 0; Actual: ' + sitAfterUpdate.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdate, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Expected: 0; Actual: ' + sitAfterUpdate.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdate, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Expected: 0; Actual: ' + sitAfterUpdate.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdate, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Expected: 0; Actual: ' + sitAfterUpdate.get(FIELD_BOOKED_PLACES));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testAsAdmin to update ipa from submitted to approved, removing Study Intake during update
     */
    @IsTest
    static void testAsAdmin_UpdateIpa_SubmittedToApproved_WithStudyIntakeToNoStudyIntake() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake__c sit = querySit(KEY_CYINTAKE);

            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sit.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake__c sitBeforeUpdate = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(1, sitBeforeUpdate.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdate, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications! Expected: 0; Actual: ' + sitBeforeUpdate.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdate, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Expected: 0; Actual: ' + sitBeforeUpdate.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdate, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Expected: 0; Actual: ' + sitBeforeUpdate.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdate, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Expected: 0; Actual: ' + sitBeforeUpdate.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdate, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Expected: 0; Actual: ' + sitBeforeUpdate.get(FIELD_BOOKED_PLACES));

            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;
            ipa.reduivy__Study_Intake__c = null;
            update ipa;

            reduivy__Study_Intake__c sitAfterUpdate = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitAfterUpdate), sitApplicationFieldsNotEmptyErrorMsg(sitAfterUpdate));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testAsAdmin to update ipa from submitted to approved, and changing Study Intake during update
     */
    @IsTest
    static void testAsAdmin_UpdateIpa_SubmittedToApproved_StudyIntake1ToStudyIntake2() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake__c sit1 = querySit(KEY_CYINTAKE);
            reduivy__Study_Intake__c sit2 = querySit(KEY_NYINTAKE);

            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sit1.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake__c sit1BeforeUpdate = querySit(KEY_CYINTAKE);
            reduivy__Study_Intake__c sit2BeforeUpdate = querySit(KEY_NYINTAKE);
            System.Assert.areEqual(1, sit1BeforeUpdate.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sit1BeforeUpdate, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications! Expected: 0; Actual: ' + sit1BeforeUpdate.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sit1BeforeUpdate, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Expected: 0; Actual: ' + sit1BeforeUpdate.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sit1BeforeUpdate, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Expected: 0; Actual: ' + sit1BeforeUpdate.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sit1BeforeUpdate, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Expected: 0; Actual: ' + sit1BeforeUpdate.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sit1BeforeUpdate, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Expected: 0; Actual: ' + sit1BeforeUpdate.get(FIELD_BOOKED_PLACES));

            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sit2BeforeUpdate), sitApplicationFieldsNotEmptyErrorMsg(sit2BeforeUpdate));

            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;
            ipa.reduivy__Study_Intake__c = sit2.Id;
            update ipa;

            reduivy__Study_Intake__c sit1AfterUpdate = querySit(KEY_CYINTAKE);
            reduivy__Study_Intake__c sit2AfterUpdate = querySit(KEY_NYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sit1AfterUpdate), sitApplicationFieldsNotEmptyErrorMsg(sit1AfterUpdate));
            System.Assert.areEqual(1, sit2AfterUpdate.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sit2AfterUpdate.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sit2AfterUpdate, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Expected: 0; Actual: ' + sit2AfterUpdate.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sit2AfterUpdate, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Expected: 0; Actual: ' + sit2AfterUpdate.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sit2AfterUpdate, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Expected: 0; Actual: ' + sit2AfterUpdate.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sit2AfterUpdate, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Expected: 0; Actual: ' + sit2AfterUpdate.get(FIELD_BOOKED_PLACES));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    @IsTest
    static void testAsAdmin_UpdateIpa_OfferToAccepted_Full() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake__c sitBeforeInsertIpa = querySit(KEY_CYINTAKE);
            List<reduivy__Individual_Program_Application__c> ipaList = new List<reduivy__Individual_Program_Application__c>();

            for(Integer i = 0; i < STUDY_INTAKE_CAPACITY; i++){
                reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_OFFER, sitBeforeInsertIpa.Id, con.Id);
                ipaList.add(ipa);
            }
            insert ipaList;

            reduivy__Study_Intake__c sitBeforeUpdateIpa = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(STUDY_INTAKE_CAPACITY, sitBeforeUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before update!');
            System.Assert.areEqual(STUDY_INTAKE_CAPACITY, sitBeforeUpdateIpa.reduivy__Approved_Applications__c, 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places before update!');
            
            for(Integer i = 0; i < STUDY_INTAKE_CAPACITY - 1; i++) {
                ipaList[i].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;
            }

            update ipaList;

            reduivy__Study_Intake__c sitAfterUpdate9Ipa = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(STUDY_INTAKE_CAPACITY, sitAfterUpdate9Ipa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(STUDY_INTAKE_CAPACITY, sitAfterUpdate9Ipa.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.areEqual(STUDY_INTAKE_CAPACITY - 1, sitAfterUpdate9Ipa.reduivy__Accepted_Applications__c, 'Wrong Accepted Applications!');
            System.Assert.areEqual(STUDY_INTAKE_CAPACITY - 1, sitAfterUpdate9Ipa.reduivy__Booked_Places__c, 'Wrong Booked Places!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdate9Ipa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdate9Ipa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications!');

            ipaList[STUDY_INTAKE_CAPACITY - 1].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;

            update ipaList[STUDY_INTAKE_CAPACITY - 1];
            
            reduivy__Study_Intake__c sitAfterUpdate1Ipa = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(STUDY_INTAKE_CAPACITY, sitAfterUpdate1Ipa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(STUDY_INTAKE_CAPACITY, sitAfterUpdate1Ipa.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.areEqual(STUDY_INTAKE_CAPACITY, sitAfterUpdate1Ipa.reduivy__Accepted_Applications__c, 'Wrong Accepted Applications!');
            System.Assert.areEqual(STUDY_INTAKE_CAPACITY, sitAfterUpdate1Ipa.reduivy__Booked_Places__c, 'Wrong Booked Places!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdate1Ipa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdate1Ipa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications!');

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description Test inserting 10 IPA with random statuses, updating 5 IPA, and asserting Study Intake rollups.
     */
    @IsTest
    static void testAsAdmin_InsertAndUpdateMultipleIpaStatuses() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        System.runAs(ADMIN_USER) {
            Contact con = getCon();
            reduivy__Study_Intake__c sit = querySit(KEY_CYINTAKE);
            
            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>{
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_DRAFT, sit.Id, con.Id),        // 0
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sit.Id, con.Id),    // 1
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REVIEWING, sit.Id, con.Id),     // 2
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_APPROVED, sit.Id, con.Id),      // 3
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_OFFER, sit.Id, con.Id),         // 4
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REJECTED, sit.Id, con.Id),      // 5
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sit.Id, con.Id),     // 6
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REVIEWING, sit.Id, con.Id),     // 7
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_CANCELLED, sit.Id, con.Id),     // 8
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_APPROVED, sit.Id, con.Id)       // 9
            };
            insert ipas;
            
            reduivy__Study_Intake__c sitAfterInsert = querySit(KEY_CYINTAKE);
            
            System.Assert.areEqual(8, sitAfterInsert.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after insert');
            System.Assert.areEqual(3, sitAfterInsert.reduivy__Approved_Applications__c, 'Approved Applications wrong after insert');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterInsert, FIELD_ACCEPTED_APPLICATIONS), 'Accepted Applications should be empty, actual: ' + sitAfterInsert.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.areEqual(1, sitAfterInsert.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after insert');
            System.Assert.areEqual(2, sitAfterInsert.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after insert');
            System.Assert.areEqual(
                sitAfterInsert.reduivy__Accepted_Applications__c, 
                sitAfterInsert.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after insert'
            );
            
            // Now update 5 of the IPAs
            ipas[1].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING;       // Submitted -> Reviewing
            ipas[2].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;        // Reviewing -> Approved
            ipas[4].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;  // Offer -> Offer Accepted
            ipas[7].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;        // Reviewing -> Approved
            ipas[8].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_CANCELLED;       // Cancelled -> Cancelled (still no rollup)
            update ipas;
            
            reduivy__Study_Intake__c sitAfterUpdate = querySit(KEY_CYINTAKE);
            
            System.Assert.areEqual(8, sitAfterUpdate.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after update');
            System.Assert.areEqual(5, sitAfterUpdate.reduivy__Approved_Applications__c, 'Approved Applications wrong after update');
            System.Assert.areEqual(1, sitAfterUpdate.reduivy__Accepted_Applications__c, 'Accepted Applications wrong after update');
            System.Assert.areEqual(1, sitAfterUpdate.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after update');
            System.Assert.areEqual(1, sitAfterUpdate.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after update');
            System.Assert.areEqual(
                sitAfterUpdate.reduivy__Accepted_Applications__c, 
                sitAfterUpdate.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after update'
            );
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description Test inserting 10 IPA with random statuses, updating 5 IPA, and asserting Study Intake rollups.
     */
    @IsTest
    static void testAsAdmin_InsertAndUpdateMultipleIpaStatuses_2() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        System.runAs(ADMIN_USER) {
            Contact con = getCon();
            reduivy__Study_Intake__c sit = querySit(KEY_CYINTAKE);
            
            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>{
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sit.Id, con.Id),    // 0
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sit.Id, con.Id),    // 1
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REVIEWING, sit.Id, con.Id),     // 2
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_APPROVED, sit.Id, con.Id),      // 3
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_APPROVED, sit.Id, con.Id),      // 4
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REJECTED, sit.Id, con.Id),      // 5
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REJECTED, sit.Id, con.Id),      // 6
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REVIEWING, sit.Id, con.Id),     // 7
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_CANCELLED, sit.Id, con.Id),     // 8
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_DRAFT, sit.Id, con.Id)          // 9
            };
            insert ipas;
            
            reduivy__Study_Intake__c sitAfterInsert = querySit(KEY_CYINTAKE);
            
            System.Assert.areEqual(8, sitAfterInsert.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after insert');
            System.Assert.areEqual(2, sitAfterInsert.reduivy__Approved_Applications__c, 'Approved Applications wrong after insert');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterInsert, FIELD_ACCEPTED_APPLICATIONS), 'Accepted Applications should be empty, actual: ' + sitAfterInsert.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.areEqual(2, sitAfterInsert.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after insert');
            System.Assert.areEqual(2, sitAfterInsert.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after insert');
            System.Assert.areEqual(
                sitAfterInsert.reduivy__Accepted_Applications__c, 
                sitAfterInsert.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after insert'
            );
            
            // Update
            ipas[0].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING;       // Submitted -> Reviewing
            ipas[2].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;        // Reviewing -> Approved
            ipas[4].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;  // Approved -> Offer Accepted
            ipas[6].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_CANCELLED;       // Rejected -> Cancelled
            ipas[9].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_CANCELLED;       // Draft -> Cancelled
            update ipas;
            
            reduivy__Study_Intake__c sitAfterUpdate = querySit(KEY_CYINTAKE);
            
            System.Assert.areEqual(7, sitAfterUpdate.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after update');
            System.Assert.areEqual(3, sitAfterUpdate.reduivy__Approved_Applications__c, 'Approved Applications wrong after update');
            System.Assert.areEqual(1, sitAfterUpdate.reduivy__Accepted_Applications__c, 'Accepted Applications wrong after update');
            System.Assert.areEqual(1, sitAfterUpdate.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after update');
            System.Assert.areEqual(2, sitAfterUpdate.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after update');
            System.Assert.areEqual(
                sitAfterUpdate.reduivy__Accepted_Applications__c, 
                sitAfterUpdate.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after update'
            );
                 
            
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }


    /**
     * @description Test inserting 10 IPA with random statuses, updating 5 IPA, and asserting Study Intake rollups.
     */
    @IsTest
    static void testAsAdmin_InsertAndUpdateMultipleIpaStatuses_3() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        System.runAs(ADMIN_USER) {
            Contact con = getCon();
            reduivy__Study_Intake__c sit = querySit(KEY_CYINTAKE);
            
            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>{
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_DRAFT, sit.Id, con.Id),           // 0
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sit.Id, con.Id),       // 1
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sit.Id, con.Id),       // 2
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REVIEWING, sit.Id, con.Id),        // 3
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_APPROVED, sit.Id, con.Id),         // 4
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REJECTED, sit.Id, con.Id),         // 5
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REJECTED, sit.Id, con.Id),         // 6
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REVIEWING, sit.Id, con.Id),        // 7
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_CANCELLED, sit.Id, con.Id),        // 8
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_APPROVED, sit.Id, con.Id)          // 9
            };
            insert ipas;
            
            reduivy__Study_Intake__c sitAfterInsert = querySit(KEY_CYINTAKE);
            
            System.Assert.areEqual(8, sitAfterInsert.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after insert');
            System.Assert.areEqual(2, sitAfterInsert.reduivy__Approved_Applications__c, 'Approved Applications wrong after insert');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterInsert, FIELD_ACCEPTED_APPLICATIONS), 'Accepted Applications should be empty, actual: ' + sitAfterInsert.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.areEqual(2, sitAfterInsert.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after insert');
            System.Assert.areEqual(2, sitAfterInsert.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after insert');
            System.Assert.areEqual(
                sitAfterInsert.reduivy__Accepted_Applications__c, 
                sitAfterInsert.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after insert'
            );
            
            // Update
            ipas[1].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING;        // Submitted -> Reviewing
            ipas[2].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING;        // Submitted -> Reviewing
            ipas[4].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;   // Approved -> Offer Accepted
            ipas[5].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_CANCELLED;        // Rejected -> Cancelled
            ipas[7].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;         // Reviewing -> Approved
            update ipas;
            
            reduivy__Study_Intake__c sitAfterUpdate = querySit(KEY_CYINTAKE);
            
            System.Assert.areEqual(7, sitAfterUpdate.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after update');
            System.Assert.areEqual(3, sitAfterUpdate.reduivy__Approved_Applications__c, 'Approved Applications wrong after update');
            System.Assert.areEqual(1, sitAfterUpdate.reduivy__Accepted_Applications__c, 'Accepted Applications wrong after update');
            System.Assert.areEqual(1, sitAfterUpdate.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after update');
            System.Assert.areEqual(3, sitAfterUpdate.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after update');
            System.Assert.areEqual(
                sitAfterUpdate.reduivy__Accepted_Applications__c, 
                sitAfterUpdate.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after update'
            );
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description Test inserting 10 IPA with random statuses, updating 5 IPA, and asserting Study Intake rollups.
     */
    @IsTest
    static void testAsAdmin_InsertAndUpdateMultipleIpaStatuses_4() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        System.runAs(ADMIN_USER) {
            Contact con = getCon();
            reduivy__Study_Intake__c sit = querySit(KEY_CYINTAKE);
            
            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>{
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_DRAFT, sit.Id, con.Id),           // 0
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sit.Id, con.Id),       // 1
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sit.Id, con.Id),       // 2
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REVIEWING, sit.Id, con.Id),        // 3
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_APPROVED, sit.Id, con.Id),         // 4
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REJECTED, sit.Id, con.Id),         // 5
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REJECTED, sit.Id, con.Id),         // 6
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REVIEWING, sit.Id, con.Id),        // 7
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_CANCELLED, sit.Id, con.Id),        // 8
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_APPROVED, sit.Id, con.Id)          // 9
            };
            insert ipas;
            
            reduivy__Study_Intake__c sitAfterInsert = querySit(KEY_CYINTAKE);
            
            System.Assert.areEqual(8, sitAfterInsert.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after insert');
            System.Assert.areEqual(2, sitAfterInsert.reduivy__Approved_Applications__c, 'Approved Applications wrong after insert');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterInsert, FIELD_ACCEPTED_APPLICATIONS), 'Accepted Applications should be empty, actual: ' + sitAfterInsert.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.areEqual(2, sitAfterInsert.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after insert');
            System.Assert.areEqual(2, sitAfterInsert.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after insert');
            System.Assert.areEqual(
                sitAfterInsert.reduivy__Accepted_Applications__c, 
                sitAfterInsert.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after insert'
            );
            
            // Update
            ipas[1].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING;        // Submitted -> Reviewing
            ipas[2].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REJECTED;         // Submitted -> Rejected
            ipas[4].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;   // Approved -> Offer Accepted
            ipas[5].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_CANCELLED;        // Rejected -> Cancelled
            ipas[7].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;         // Reviewing -> Approved
            update ipas;
            
            reduivy__Study_Intake__c sitAfterUpdate = querySit(KEY_CYINTAKE);
            
            System.Assert.areEqual(7, sitAfterUpdate.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after update');
            System.Assert.areEqual(3, sitAfterUpdate.reduivy__Approved_Applications__c, 'Approved Applications wrong after update');
            System.Assert.areEqual(1, sitAfterUpdate.reduivy__Accepted_Applications__c, 'Accepted Applications wrong after update');
            System.Assert.areEqual(2, sitAfterUpdate.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after update');
            System.Assert.areEqual(2, sitAfterUpdate.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after update');
            System.Assert.areEqual(
                sitAfterUpdate.reduivy__Accepted_Applications__c, 
                sitAfterUpdate.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after update'
            );
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description Test inserting 10 IPA with random statuses, updating 5 IPA, and asserting Study Intake rollups.
     */
    @IsTest
    static void testAsAdmin_InsertAndUpdateMultipleIpaStatuses_5() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        System.runAs(ADMIN_USER) {
            Contact con = getCon();
            reduivy__Study_Intake__c sit = querySit(KEY_CYINTAKE);
            
            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>{
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_DRAFT, sit.Id, con.Id),           // 0
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sit.Id, con.Id),       // 1
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REVIEWING, sit.Id, con.Id),        // 2
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_APPROVED, sit.Id, con.Id),         // 3
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_OFFER, sit.Id, con.Id),            // 4
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REJECTED, sit.Id, con.Id),         // 5
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REVIEWING, sit.Id, con.Id),        // 6
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_APPROVED, sit.Id, con.Id),         // 7
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_CANCELLED, sit.Id, con.Id),        // 8
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REJECTED, sit.Id, con.Id)          // 9
            };
            insert ipas;
            
            reduivy__Study_Intake__c sitAfterInsert = querySit(KEY_CYINTAKE);
            
            System.Assert.areEqual(8, sitAfterInsert.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after insert');
            System.Assert.areEqual(3, sitAfterInsert.reduivy__Approved_Applications__c, 'Approved Applications wrong after insert');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterInsert, FIELD_ACCEPTED_APPLICATIONS), 'Accepted Applications should be empty, actual: ' + sitAfterInsert.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.areEqual(2, sitAfterInsert.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after insert');
            System.Assert.areEqual(2, sitAfterInsert.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after insert');
            System.Assert.areEqual(
                sitAfterInsert.reduivy__Accepted_Applications__c, 
                sitAfterInsert.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after insert'
            );
            
            // Update
            ipas[1].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING;        // Submitted -> Reviewing
            ipas[2].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;         // Reviewing -> Approved
            ipas[4].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;   // Offer -> Offer Accepted
            ipas[5].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_CANCELLED;        // Rejected -> Cancelled
            ipas[7].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REJECTED;         // Approved -> Rejected
            update ipas;
            
            reduivy__Study_Intake__c sitAfterUpdate = querySit(KEY_CYINTAKE);
            
            System.Assert.areEqual(7, sitAfterUpdate.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after update');
            System.Assert.areEqual(3, sitAfterUpdate.reduivy__Approved_Applications__c, 'Approved Applications wrong after update');
            System.Assert.areEqual(1, sitAfterUpdate.reduivy__Accepted_Applications__c, 'Accepted Applications wrong after update');
            System.Assert.areEqual(2, sitAfterUpdate.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after update');
            System.Assert.areEqual(2, sitAfterUpdate.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after update');
            System.Assert.areEqual(
                sitAfterUpdate.reduivy__Accepted_Applications__c, 
                sitAfterUpdate.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after update'
            );
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }


    /**
     * @description Test inserting 10 IPA with random statuses, updating 5 IPA, and asserting Study Intake rollups. Over capacity is tested
     */
    @IsTest
    static void testAsAdmin_InsertAndUpdateMultipleIpaStatuses_OverCapacity() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        System.runAs(ADMIN_USER) {
            Contact con = getCon();
            reduivy__Study_Intake__c sit = querySit(KEY_CYINTAKE);
            
            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>{
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_DRAFT, sit.Id, con.Id),           // 0
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sit.Id, con.Id),       // 1
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REVIEWING, sit.Id, con.Id),        // 2
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED, sit.Id, con.Id),   // 3
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_APPROVED, sit.Id, con.Id),         // 4
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_APPROVED, sit.Id, con.Id),         // 5
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REVIEWING, sit.Id, con.Id),        // 6
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_APPROVED, sit.Id, con.Id),         // 7
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_CANCELLED, sit.Id, con.Id),        // 8
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REJECTED, sit.Id, con.Id)          // 9
            };
            insert ipas;
            
            reduivy__Study_Intake__c sitAfterInsert = querySit(KEY_CYINTAKE);
            
            System.Assert.areEqual(8, sitAfterInsert.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after insert');
            System.Assert.areEqual(4, sitAfterInsert.reduivy__Approved_Applications__c, 'Approved Applications wrong after insert');
            System.Assert.areEqual(1, sitAfterInsert.reduivy__Accepted_Applications__c, 'Accepted Applications wrong after insert');
            System.Assert.areEqual(1, sitAfterInsert.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after insert');
            System.Assert.areEqual(2, sitAfterInsert.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after insert');
            System.Assert.areEqual(
                sitAfterInsert.reduivy__Accepted_Applications__c, 
                sitAfterInsert.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after insert'
            );
            
            // Update
            ipas[1].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;      // Submitted -> OFFER_ACCEPTED
            ipas[2].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;      // Reviewing -> OFFER_ACCEPTED
            ipas[4].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;      // Offer -> OFFER_ACCEPTED
            ipas[5].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;      // Rejected -> OFFER_ACCEPTED
            ipas[7].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;      // Approved -> OFFER_ACCEPTED

            update ipas;

            
            reduivy__Study_Intake__c sitAfterUpdate = querySit(KEY_CYINTAKE);
            
            System.Assert.areEqual(8, sitAfterUpdate.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after insert');
            System.Assert.areEqual(6, sitAfterUpdate.reduivy__Approved_Applications__c, 'Approved Applications wrong after insert');
            System.Assert.areEqual(6, sitAfterUpdate.reduivy__Accepted_Applications__c, 'Accepted Applications wrong after insert');
            System.Assert.areEqual(1, sitAfterUpdate.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after insert');
            System.Assert.areEqual(1, sitAfterUpdate.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after insert');
            System.Assert.areEqual(
                sitAfterUpdate.reduivy__Accepted_Applications__c, 
                sitAfterUpdate.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after insert'
            );
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    @IsTest
    static void testAsStudent_CreateIpa_Approved() {
        
        User studentUser = testFactory.getStudentUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake__c sitBefore = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBefore), sitApplicationFieldsNotEmptyErrorMsg(sitBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_APPROVED, sitBefore.Id, con.Id);
            insert ipa;
            
            reduivy__Study_Intake__c sitAfter = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(1, sitAfter.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sitAfter.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Excepted: 0; Actual: ' + sitAfter.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Excepted: 0; Actual: ' + sitAfter.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Excepted: 0; Actual: ' + sitAfter.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Excepted: 0; Actual: ' + sitAfter.get(FIELD_BOOKED_PLACES));

        }
        
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    @IsTest
    static void testAsStudent_CreateIpa_Offer() {
        User studentUser = testFactory.getStudentUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake__c sitBefore = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBefore), sitApplicationFieldsNotEmptyErrorMsg(sitBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_OFFER, sitBefore.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake__c sitAfter = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(1, sitAfter.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sitAfter.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Excepted: 0; Actual: ' + sitAfter.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Excepted: 0; Actual: ' + sitAfter.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Excepted: 0; Actual: ' + sitAfter.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Excepted: 0; Actual: ' + sitAfter.get(FIELD_BOOKED_PLACES));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    @IsTest
    static void testAsStudent_CreateIpa_OfferAccepted() {
        User studentUser = testFactory.getStudentUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake__c sitBefore = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBefore), sitApplicationFieldsNotEmptyErrorMsg(sitBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED, sitBefore.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake__c sitAfter = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(1, sitAfter.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sitAfter.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.areEqual(1, sitAfter.reduivy__Accepted_Applications__c, 'Wrong Accepted Applications!');
            System.Assert.areEqual(1, sitAfter.reduivy__Booked_Places__c, 'Wrong Booked Places!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Excepted: 0; Actual: ' + sitAfter.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Excepted: 0; Actual: ' + sitAfter.get(FIELD_REVIEWING_APPLICATIONS));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    @IsTest
    static void testAsStudent_CreateIpa_OfferDeclined() {
        User studentUser = testFactory.getStudentUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake__c sitBefore = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBefore), sitApplicationFieldsNotEmptyErrorMsg(sitBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_OFFER_DECLINED, sitBefore.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake__c sitAfter = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(1, sitAfter.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sitAfter.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Excepted: 0; Actual: ' + sitAfter.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Excepted: 0; Actual: ' + sitAfter.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Excepted: 0; Actual: ' + sitAfter.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Excepted: 0; Actual: ' + sitAfter.get(FIELD_BOOKED_PLACES));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    @IsTest
    static void testAsStudent_CreateIpa_Rejected() {
        User studentUser = testFactory.getStudentUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake__c sitBefore = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBefore), sitApplicationFieldsNotEmptyErrorMsg(sitBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REJECTED, sitBefore.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake__c sitAfter = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(1, sitAfter.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sitAfter.reduivy__Rejected_Applications__c, 'Wrong Rejected Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Excepted: 0; Actual: ' + sitAfter.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications! Excepted: 0; Actual: ' + sitAfter.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Excepted: 0; Actual: ' + sitAfter.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Excepted: 0; Actual: ' + sitAfter.get(FIELD_BOOKED_PLACES));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    @IsTest
    static void testAsStudent_CreateIpa_Reviewing() {
        User studentUser = testFactory.getStudentUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake__c sitBefore = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBefore), sitApplicationFieldsNotEmptyErrorMsg(sitBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REVIEWING, sitBefore.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake__c sitAfter = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(1, sitAfter.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sitAfter.reduivy__Reviewing_Applications__c, 'Wrong Reviewing Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Excepted: 0; Actual: ' + sitAfter.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Excepted: 0; Actual: ' + sitAfter.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications! Excepted: 0; Actual: ' + sitAfter.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Excepted: 0; Actual: ' + sitAfter.get(FIELD_BOOKED_PLACES));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    @IsTest
    static void testAsStudent_CreateIpa_ReviewingAwaitingDocs() {
        User studentUser = testFactory.getStudentUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake__c sitBefore = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBefore), sitApplicationFieldsNotEmptyErrorMsg(sitBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(APPLICATION_STATUS_REVIEWING_AWAITING_DOCS, sitBefore.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake__c sitAfter = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(1, sitAfter.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sitAfter.reduivy__Reviewing_Applications__c, 'Wrong Reviewing Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Excepted: 0; Actual: ' + sitAfter.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Excepted: 0; Actual: ' + sitAfter.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications! Excepted: 0; Actual: ' + sitAfter.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Excepted: 0; Actual: ' + sitAfter.get(FIELD_BOOKED_PLACES));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    @IsTest
    static void testAsStudent_CreateIpa_Submitted() {
        User studentUser = testFactory.getStudentUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake__c sitBefore = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBefore), sitApplicationFieldsNotEmptyErrorMsg(sitBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sitBefore.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake__c sitAfter = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(1, sitAfter.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications! Excepted: 0; Actual: ' + sitAfter.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Excepted: 0; Actual: ' + sitAfter.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Excepted: 0; Actual: ' + sitAfter.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Excepted: 0; Actual: ' + sitAfter.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfter, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Excepted: 0; Actual: ' + sitAfter.get(FIELD_BOOKED_PLACES));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    @IsTest
    static void testAsStudent_CreateIpa_Draft() {
        User studentUser = testFactory.getStudentUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake__c sitBefore = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBefore), sitApplicationFieldsNotEmptyErrorMsg(sitBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_DRAFT, sitBefore.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake__c sitAfter = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitAfter), sitApplicationFieldsNotEmptyErrorMsg(sitAfter));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    @IsTest
    static void testAsStudent_CreateIpa_Cancelled() {
        User studentUser = testFactory.getStudentUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake__c sitBefore = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBefore), sitApplicationFieldsNotEmptyErrorMsg(sitBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_CANCELLED, sitBefore.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake__c sitAfter = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitAfter), sitApplicationFieldsNotEmptyErrorMsg(sitAfter));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testAsStudent to update ipa from draft to submitted
     */
    @IsTest
    static void testAsStudent_UpdateIpa_DraftToSubmitted() {
        User studentUser = testFactory.getStudentUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake__c sitBeforeInsertIpa = querySit(KEY_CYINTAKE);
            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_DRAFT, sitBeforeInsertIpa.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake__c sitBeforeUpdateIpa = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBeforeUpdateIpa), sitApplicationFieldsNotEmptyErrorMsg(sitBeforeUpdateIpa));

            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_SUBMITTED;
            update ipa;

            reduivy__Study_Intake__c sitAfterUpdateIpa = querySit(KEY_CYINTAKE);

            System.Assert.areEqual(1, sitAfterUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications! Excepted: 0; Actual: ' + sitAfterUpdateIpa.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Excepted: 0; Actual: ' + sitAfterUpdateIpa.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Excepted: 0; Actual: ' + sitAfterUpdateIpa.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Excepted: 0; Actual: ' + sitAfterUpdateIpa.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Excepted: 0; Actual: ' + sitAfterUpdateIpa.get(FIELD_BOOKED_PLACES));
            
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    @IsTest
    static void testAsStudent_UpdateIpa_SubmittedToReviewing() {
        User studentUser = testFactory.getStudentUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake__c sitBeforeInsertIpa = querySit(KEY_CYINTAKE);
            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sitBeforeInsertIpa.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake__c sitBeforeUpdateIpa = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(1, sitBeforeUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places before update!');

            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING;
            update ipa;

            reduivy__Study_Intake__c sitAfterUpdateIpa = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(1, sitAfterUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sitAfterUpdateIpa.reduivy__Reviewing_Applications__c, 'Wrong Reviewing Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places!');
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    @IsTest
    static void testAsStudent_UpdateIpa_ReviewingToApproved() {
        User studentUser = testFactory.getStudentUser();
    
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake__c sitBeforeInsertIpa = querySit(KEY_CYINTAKE);
            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REVIEWING, sitBeforeInsertIpa.Id, con.Id);
            insert ipa;
    
            reduivy__Study_Intake__c sitBeforeUpdateIpa = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(1, sitBeforeUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before update!');
            System.Assert.areEqual(1, sitBeforeUpdateIpa.reduivy__Reviewing_Applications__c, 'Wrong Reviewing Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places before update!');
    
            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;
            update ipa;
    
            reduivy__Study_Intake__c sitAfterUpdateIpa = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(1, sitAfterUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sitAfterUpdateIpa.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places!');
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }
    
    @IsTest
    static void testAsStudent_UpdateIpa_ApprovedToOffer() {
        User studentUser = testFactory.getStudentUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake__c sitBeforeInsertIpa = querySit(KEY_CYINTAKE);
            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_APPROVED, sitBeforeInsertIpa.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake__c sitBeforeUpdateIpa = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(1, sitBeforeUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before update!');
            System.Assert.areEqual(1, sitBeforeUpdateIpa.reduivy__Approved_Applications__c, 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places before update!');

            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER;
            update ipa;

            reduivy__Study_Intake__c sitAfterUpdateIpa = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(1, sitAfterUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sitAfterUpdateIpa.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places!');
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    @IsTest
    static void testAsStudent_UpdateIpa_OfferToAccepted() {
        User studentUser = testFactory.getStudentUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake__c sitBeforeInsertIpa = querySit(KEY_CYINTAKE);
            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_OFFER, sitBeforeInsertIpa.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake__c sitBeforeUpdateIpa = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(1, sitBeforeUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before update!');
            System.Assert.areEqual(1, sitBeforeUpdateIpa.reduivy__Approved_Applications__c, 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places before update!');

            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;
            update ipa;

            reduivy__Study_Intake__c sitAfterUpdateIpa = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(1, sitAfterUpdateIpa.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.areEqual(1, sitAfterUpdateIpa.reduivy__Accepted_Applications__c, 'Wrong Accepted Applications!');
            System.Assert.areEqual(1, sitAfterUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sitAfterUpdateIpa.reduivy__Booked_Places__c, 'Wrong Booked Places!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications!');

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    @IsTest
    static void testAsStudent_UpdateIpa_OfferToDeclined() {
        User studentUser = testFactory.getStudentUser();
    
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake__c sitBeforeInsertIpa = querySit(KEY_CYINTAKE);
            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_OFFER, sitBeforeInsertIpa.Id, con.Id);
            insert ipa;
    
            reduivy__Study_Intake__c sitBeforeUpdateIpa = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(1, sitBeforeUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before update!');
            System.Assert.areEqual(1, sitBeforeUpdateIpa.reduivy__Approved_Applications__c, 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places before update!');
    
            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_DECLINED;
            update ipa;
    
            reduivy__Study_Intake__c sitAfterUpdateIpa = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(1, sitAfterUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sitBeforeUpdateIpa.reduivy__Approved_Applications__c, 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places!');
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }
    
    @IsTest
    static void testAsStudent_UpdateIpa_ReviewingToRejected() {
        User studentUser = testFactory.getStudentUser();
    
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake__c sitBeforeInsertIpa = querySit(KEY_CYINTAKE);
            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REVIEWING, sitBeforeInsertIpa.Id, con.Id);
            insert ipa;
    
            reduivy__Study_Intake__c sitBeforeUpdateIpa = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(1, sitBeforeUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before update!');
            System.Assert.areEqual(1, sitBeforeUpdateIpa.reduivy__Reviewing_Applications__c, 'Wrong Reviewing Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places before update!');
    
            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REJECTED;
            update ipa;
    
            reduivy__Study_Intake__c sitAfterUpdateIpa = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(1, sitAfterUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sitAfterUpdateIpa.reduivy__Rejected_Applications__c, 'Wrong Rejected Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places!');
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    @IsTest
    static void testAsStudent_UpdateIpa_SubmittedToCancelled() {
        User studentUser = testFactory.getStudentUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake__c sitBeforeInsertIpa = querySit(KEY_CYINTAKE);
            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sitBeforeInsertIpa.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake__c sitBeforeUpdateIpa = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(1, sitBeforeUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before update!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places before update!');

            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_CANCELLED;
            update ipa;

            reduivy__Study_Intake__c sitAfterUpdateIpa = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitAfterUpdateIpa), sitApplicationFieldsNotEmptyErrorMsg(sitAfterUpdateIpa));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testAsStudent to delete and undelete IPA with status Submitted
     */
    @IsTest
    static void testAsStudent_DeleteUndeleteIpa_Submitted() {
        User studentUser = testFactory.getStudentUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake__c sitBeforeInsert = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBeforeInsert), sitApplicationFieldsNotEmptyErrorMsg(sitBeforeInsert));

            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>();

            for (Integer i = 0; i < 5; i++) {
                ipas.add(newIpaWithSit(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sitBeforeInsert.Id, con.Id));
            }
            insert ipas;

            reduivy__Study_Intake__c sitBeforeDelete = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(5, sitBeforeDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before delete!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeDelete, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications before delete! Expected: 0; Actual: ' + sitBeforeDelete.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before delete! Expected: 0; Actual: ' + sitBeforeDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before delete! Expected: 0; Actual: ' + sitBeforeDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places before delete! Expected: 0; Actual: ' + sitBeforeDelete.get(FIELD_BOOKED_PLACES));
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before delete! Expected: 0; Actual: ' + sitBeforeDelete.get(FIELD_REVIEWING_APPLICATIONS));

            delete ipas[0];

            reduivy__Study_Intake__c sitAfterDelete = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(4, sitAfterDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after delete!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterDelete, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications after delete! Expected: 0; Actual: ' + sitAfterDelete.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after delete! Expected: 0; Actual: ' + sitAfterDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after delete! Expected: 0; Actual: ' + sitAfterDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after delete! Expected: 0; Actual: ' + sitAfterDelete.get(FIELD_BOOKED_PLACES));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after delete! Expected: 0; Actual: ' + sitAfterDelete.get(FIELD_REVIEWING_APPLICATIONS));

            undelete ipas[0];

            reduivy__Study_Intake__c sitAfterUndelete = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(5, sitAfterUndelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after undelete!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUndelete, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications after undelete! Expected: 0; Actual: ' + sitAfterUndelete.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUndelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after undelete! Expected: 0; Actual: ' + sitAfterUndelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUndelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after undelete! Expected: 0; Actual: ' + sitAfterUndelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUndelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after undelete! Expected: 0; Actual: ' + sitAfterUndelete.get(FIELD_BOOKED_PLACES));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUndelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after undelete! Expected: 0; Actual: ' + sitAfterUndelete.get(FIELD_REVIEWING_APPLICATIONS));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }


    /**
     * @description testAsStudent to delete and undelete IPA with status Draft
     */
    @IsTest
    static void testAsStudent_DeleteUndeleteIpa_Draft() {
        User studentUser = testFactory.getStudentUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake__c sitBeforeInsert = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBeforeInsert), sitApplicationFieldsNotEmptyErrorMsg(sitBeforeInsert));
            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>();

            for (Integer i = 0; i < 5; i++) {
                ipas.add(newIpaWithSit(IPA_Helper.APPLICATION_STATUS_DRAFT, sitBeforeInsert.Id, con.Id));
            }
            insert ipas;

            reduivy__Study_Intake__c sitBeforeDelete = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBeforeDelete), sitApplicationFieldsNotEmptyErrorMsg(sitBeforeDelete));

            delete ipas[0];
            reduivy__Study_Intake__c sitAfterDelete = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitAfterDelete), sitApplicationFieldsNotEmptyErrorMsg(sitAfterDelete));

            undelete ipas[0];
            reduivy__Study_Intake__c sitAfterUndelete = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitAfterUndelete), sitApplicationFieldsNotEmptyErrorMsg(sitAfterUndelete));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testAsStudent to delete and undelete IPA with status Reviewing
     */
    @IsTest
    static void testAsStudent_DeleteUndeleteIpa_Reviewing() {
        User studentUser = testFactory.getStudentUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake__c sitBeforeInsert = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBeforeInsert), sitApplicationFieldsNotEmptyErrorMsg(sitBeforeInsert));

            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>();

            for (Integer i = 0; i < 5; i++) {
                ipas.add(newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REVIEWING, sitBeforeInsert.Id, con.Id));
            }
            insert ipas;

            reduivy__Study_Intake__c sitBeforeDelete = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(5, sitBeforeDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before delete!');
            System.Assert.areEqual(5, sitBeforeDelete.reduivy__Reviewing_Applications__c, 'Wrong Reviewing Applications before delete!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeDelete, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications before delete! Expected: 0; Actual: ' + sitBeforeDelete.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before delete! Expected: 0; Actual: ' + sitBeforeDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before delete! Expected: 0; Actual: ' + sitBeforeDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places before delete! Expected: 0; Actual: ' + sitBeforeDelete.get(FIELD_BOOKED_PLACES));

            delete ipas[0];
            reduivy__Study_Intake__c sitAfterDelete = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(4, sitAfterDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after delete!');
            System.Assert.areEqual(4, sitAfterDelete.reduivy__Reviewing_Applications__c, 'Wrong Reviewing Applications after delete!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterDelete, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications after delete! Expected: 0; Actual: ' + sitAfterDelete.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after delete! Expected: 0; Actual: ' + sitAfterDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after delete! Expected: 0; Actual: ' + sitAfterDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after delete! Expected: 0; Actual: ' + sitAfterDelete.get(FIELD_BOOKED_PLACES));

            undelete ipas[0];
            reduivy__Study_Intake__c sitAfterUndelete = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(5, sitAfterUndelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after undelete!');
            System.Assert.areEqual(5, sitAfterUndelete.reduivy__Reviewing_Applications__c, 'Wrong Reviewing Applications after undelete!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUndelete, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications after undelete! Expected: 0; Actual: ' + sitAfterUndelete.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUndelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after undelete! Expected: 0; Actual: ' + sitAfterUndelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUndelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after undelete! Expected: 0; Actual: ' + sitAfterUndelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUndelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after undelete! Expected: 0; Actual: ' + sitAfterUndelete.get(FIELD_BOOKED_PLACES));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testAsStudent to delete and undelete IPA with status Approved
     */
    @IsTest
    static void testAsStudent_DeleteUndeleteIpa_Approved() {
        User studentUser = testFactory.getStudentUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake__c sitBeforeInsert = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBeforeInsert), sitApplicationFieldsNotEmptyErrorMsg(sitBeforeInsert));

            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>();

            for (Integer i = 0; i < 5; i++) {
                ipas.add(newIpaWithSit(IPA_Helper.APPLICATION_STATUS_APPROVED, sitBeforeInsert.Id, con.Id));
            }
            insert ipas;

            reduivy__Study_Intake__c sitBeforeDelete = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(5, sitBeforeDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before delete!');
            System.Assert.areEqual(5, sitBeforeDelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications before delete!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before delete! Expected: 0; Actual: ' + sitBeforeDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before delete! Expected: 0; Actual: ' + sitBeforeDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before delete! Expected: 0; Actual: ' + sitBeforeDelete.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places before delete! Expected: 0; Actual: ' + sitBeforeDelete.get(FIELD_BOOKED_PLACES));

            delete ipas[0];
            reduivy__Study_Intake__c sitAfterDelete = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(4, sitAfterDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after delete!');
            System.Assert.areEqual(4, sitAfterDelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications after delete!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after delete! Expected: 0; Actual: ' + sitAfterDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after delete! Expected: 0; Actual: ' + sitAfterDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after delete! Expected: 0; Actual: ' + sitAfterDelete.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after delete! Expected: 0; Actual: ' + sitAfterDelete.get(FIELD_BOOKED_PLACES));

            undelete ipas[0];
            reduivy__Study_Intake__c sitAfterUndelete = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(5, sitAfterUndelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after undelete!');
            System.Assert.areEqual(5, sitAfterUndelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications after undelete!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUndelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after undelete! Expected: 0; Actual: ' + sitAfterUndelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUndelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after undelete! Expected: 0; Actual: ' + sitAfterUndelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUndelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after undelete! Expected: 0; Actual: ' + sitAfterUndelete.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUndelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after undelete! Expected: 0; Actual: ' + sitAfterUndelete.get(FIELD_BOOKED_PLACES));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testAsStudent to delete and undelete IPA with status Offer
     */
    @IsTest
    static void testAsStudent_DeleteUndeleteIpa_Offer() {
        User studentUser = testFactory.getStudentUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake__c sitBeforeInsert = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBeforeInsert), sitApplicationFieldsNotEmptyErrorMsg(sitBeforeInsert));

            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>();

            for (Integer i = 0; i < 5; i++) {
                ipas.add(newIpaWithSit(IPA_Helper.APPLICATION_STATUS_OFFER, sitBeforeInsert.Id, con.Id));
            }
            insert ipas;

            reduivy__Study_Intake__c sitBeforeDelete = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(5, sitBeforeDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before delete!');
            System.Assert.areEqual(5, sitBeforeDelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications before delete!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before delete! Expected: 0; Actual: ' + sitBeforeDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before delete! Expected: 0; Actual: ' + sitBeforeDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before delete! Expected: 0; Actual: ' + sitBeforeDelete.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places before delete! Expected: 0; Actual: ' + sitBeforeDelete.get(FIELD_BOOKED_PLACES));

            delete ipas[0];
            reduivy__Study_Intake__c sitAfterDelete = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(4, sitAfterDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after delete!');
            System.Assert.areEqual(4, sitAfterDelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications after delete!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after delete! Expected: 0; Actual: ' + sitAfterDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after delete! Expected: 0; Actual: ' + sitAfterDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after delete! Expected: 0; Actual: ' + sitAfterDelete.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after delete! Expected: 0; Actual: ' + sitAfterDelete.get(FIELD_BOOKED_PLACES));

            undelete ipas[0];
            reduivy__Study_Intake__c sitAfterUndelete = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(5, sitAfterUndelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after undelete!');
            System.Assert.areEqual(5, sitAfterUndelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications after undelete!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUndelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after undelete! Expected: 0; Actual: ' + sitAfterUndelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUndelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after undelete! Expected: 0; Actual: ' + sitAfterUndelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUndelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after undelete! Expected: 0; Actual: ' + sitAfterUndelete.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUndelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after undelete! Expected: 0; Actual: ' + sitAfterUndelete.get(FIELD_BOOKED_PLACES));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testAsStudent to delete and undelete IPA with status Offer Accepted
     */
    @IsTest
    static void testAsStudent_DeleteUndeleteIpa_OfferAccepted() {
        User studentUser = testFactory.getStudentUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake__c sitBeforeInsert = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBeforeInsert), sitApplicationFieldsNotEmptyErrorMsg(sitBeforeInsert));


            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>();

            for (Integer i = 0; i < 5; i++) {
                ipas.add(newIpaWithSit(IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED, sitBeforeInsert.Id, con.Id));
            }
            insert ipas;

            reduivy__Study_Intake__c sitBeforeDelete = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(5, sitBeforeDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before delete!');
            System.Assert.areEqual(5, sitBeforeDelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications before delete!');
            System.Assert.areEqual(5, sitBeforeDelete.reduivy__Accepted_Applications__c, 'Wrong Accepted Applications before delete!');
            System.Assert.areEqual(5, sitBeforeDelete.reduivy__Booked_Places__c, 'Wrong Booked Places before delete!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before delete! Expected: 0; Actual: ' + sitBeforeDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before delete! Expected: 0; Actual: ' + sitBeforeDelete.get(FIELD_REVIEWING_APPLICATIONS));

            delete ipas[0];
            reduivy__Study_Intake__c sitAfterDelete = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(4, sitAfterDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after delete!');
            System.Assert.areEqual(4, sitAfterDelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications after delete!');
            System.Assert.areEqual(4, sitAfterDelete.reduivy__Accepted_Applications__c, 'Wrong Accepted Applications after delete!');
            System.Assert.areEqual(4, sitAfterDelete.reduivy__Booked_Places__c, 'Wrong Booked Places after delete!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after delete! Expected: 0; Actual: ' + sitAfterDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after delete! Expected: 0; Actual: ' + sitAfterDelete.get(FIELD_REVIEWING_APPLICATIONS));

            undelete ipas[0];
            reduivy__Study_Intake__c sitAfterUndelete = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(5, sitAfterUndelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after undelete!');
            System.Assert.areEqual(5, sitAfterUndelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications after undelete!');
            System.Assert.areEqual(5, sitAfterUndelete.reduivy__Accepted_Applications__c, 'Wrong Accepted Applications after undelete!');
            System.Assert.areEqual(5, sitAfterUndelete.reduivy__Booked_Places__c, 'Wrong Booked Places after delete!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUndelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after undelete! Expected: 0; Actual: ' + sitAfterUndelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUndelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after undelete! Expected: 0; Actual: ' + sitAfterUndelete.get(FIELD_REVIEWING_APPLICATIONS));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }


    /**
     * @description testAsStudent to delete and undelete IPA with status Offer Declined
     */
    @IsTest
    static void testAsStudent_DeleteUndeleteIpa_OfferDeclined() {
        User studentUser = testFactory.getStudentUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake__c sitBeforeInsert = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBeforeInsert), sitApplicationFieldsNotEmptyErrorMsg(sitBeforeInsert));

            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>();

            for (Integer i = 0; i < 5; i++) {
                ipas.add(newIpaWithSit(IPA_Helper.APPLICATION_STATUS_OFFER_DECLINED, sitBeforeInsert.Id, con.Id));
            }
            insert ipas;

            reduivy__Study_Intake__c sitBeforeDelete = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(5, sitBeforeDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before delete!');
            System.Assert.areEqual(5, sitBeforeDelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications before delete!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before delete! Expected: 0; Actual: ' + sitBeforeDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before delete! Expected: 0; Actual: ' + sitBeforeDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before delete! Expected: 0; Actual: ' + sitBeforeDelete.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places before delete! Expected: 0; Actual: ' + sitBeforeDelete.get(FIELD_BOOKED_PLACES));

            delete ipas[0];
            reduivy__Study_Intake__c sitAfterDelete = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(4, sitAfterDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after delete!');
            System.Assert.areEqual(4, sitAfterDelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications after delete!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after delete! Expected: 0; Actual: ' + sitAfterDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after delete! Expected: 0; Actual: ' + sitAfterDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after delete! Expected: 0; Actual: ' + sitAfterDelete.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after delete! Expected: 0; Actual: ' + sitAfterDelete.get(FIELD_BOOKED_PLACES));

            undelete ipas[0];
            reduivy__Study_Intake__c sitAfterUndelete = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(5, sitAfterUndelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after undelete!');
            System.Assert.areEqual(5, sitAfterUndelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications after undelete!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUndelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after undelete! Expected: 0; Actual: ' + sitAfterUndelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUndelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after undelete! Expected: 0; Actual: ' + sitAfterUndelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUndelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after undelete! Expected: 0; Actual: ' + sitAfterUndelete.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUndelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after undelete! Expected: 0; Actual: ' + sitAfterUndelete.get(FIELD_BOOKED_PLACES));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testAsStudent to delete and undelete IPA with status Cancelled
     */
    @IsTest
    static void testAsStudent_DeleteUndeleteIpa_Cancelled() {
        User studentUser = testFactory.getStudentUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake__c sitBeforeInsert = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBeforeInsert), sitApplicationFieldsNotEmptyErrorMsg(sitBeforeInsert));

            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>();

            for (Integer i = 0; i < 5; i++) {
                ipas.add(newIpaWithSit(IPA_Helper.APPLICATION_STATUS_CANCELLED, sitBeforeInsert.Id, con.Id));
            }
            insert ipas;

            reduivy__Study_Intake__c sitBeforeDelete = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBeforeDelete), sitApplicationFieldsNotEmptyErrorMsg(sitBeforeDelete));

            delete ipas[0];
            reduivy__Study_Intake__c sitAfterDelete = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitAfterDelete), sitApplicationFieldsNotEmptyErrorMsg(sitAfterDelete));

            undelete ipas[0];
            reduivy__Study_Intake__c sitAfterUndelete = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitAfterUndelete), sitApplicationFieldsNotEmptyErrorMsg(sitAfterUndelete));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testAsStudent to rollup to a nonexist field
     */
    @IsTest
    static void testAsStudent_RollupFieldNotFound() {
        User studentUser = testFactory.getStudentUser();

        IPA_Helper.isNegativeTests = true;
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake__c sitBefore = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBefore), sitApplicationFieldsNotEmptyErrorMsg(sitBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_DRAFT, sitBefore.Id, con.Id);
            try{
                insert ipa;
                System.Assert.fail('Should be failed if reduivy__Rollup_Field_API_Name__c is not found!');
            } catch (Exception exp) {
                System.Assert.isTrue(
                    exp.getMessage().contains(getSitInvalidFieldErrorMessage()), 
                    'Wrong error message! Expected: ' + getSitInvalidFieldErrorMessage() + '; Actual: ' + exp.getMessage()
                );
            }

            reduivy__Study_Intake__c sitAfter = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitAfter), sitApplicationFieldsNotEmptyErrorMsg(sitAfter));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testAsStudent to rollup a nonexist ipa application status, no error should be thrown and will be simply ignored
     */
    @IsTest
    static void testAsStudent_ApplicationStatusConfigNotFound() {
        User studentUser = testFactory.getStudentUser();

        IPA_Helper.isNegativeTests = true;
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake__c sitBefore = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBefore), sitApplicationFieldsNotEmptyErrorMsg(sitBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_CANCELLED, sitBefore.Id, con.Id);
            insert ipa;


            reduivy__Study_Intake__c sitAfter = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitAfter), sitApplicationFieldsNotEmptyErrorMsg(sitAfter));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testAsStudent to rollup to a date field
     */
    @IsTest
    static void testAsStudent_RollupFieldIsNotNumber() {
        User studentUser = testFactory.getStudentUser();

        IPA_Helper.isNegativeTests = true;
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake__c sitBefore = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBefore), sitApplicationFieldsNotEmptyErrorMsg(sitBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sitBefore.Id, con.Id);
            try{
                insert ipa;
                System.Assert.fail('Should be failed if reduivy__Rollup_Field_API_Name__c is not number field!');
            } catch (Exception exp) {
                System.Assert.isTrue(
                    exp.getMessage().contains(getSitInvalidFieldErrorMessage()), 
                    'Wrong error message! Expected: ' + getSitInvalidFieldErrorMessage() + '; Actual: ' + exp.getMessage()
                );
            }

            reduivy__Study_Intake__c sitAfter = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitAfter), sitApplicationFieldsNotEmptyErrorMsg(sitAfter));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testAsStudent to rollup to a formula number field
     */
    @IsTest
    static void testAsStudent_RollupFieldIsFormulaNumberField() {
        User studentUser = testFactory.getStudentUser();

        IPA_Helper.isNegativeTests = true;
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake__c sitBefore = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBefore), sitApplicationFieldsNotEmptyErrorMsg(sitBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_APPROVED, sitBefore.Id, con.Id);
            try{
                insert ipa;
                System.Assert.fail('Should be failed if reduivy__Rollup_Field_API_Name__c is formula field!');
            } catch (Exception exp) {
                System.Assert.isTrue(
                    exp.getMessage().contains(getSitInvalidFieldErrorMessage()), 
                    'Wrong error message! Expected: ' + getSitInvalidFieldErrorMessage() + '; Actual: ' + exp.getMessage()
                );
            }

            reduivy__Study_Intake__c sitAfter = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitAfter), sitApplicationFieldsNotEmptyErrorMsg(sitAfter));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    @Istest
    static void testAsStudent_CreateIpa_Approved_NoStudyIntake(){
        User studentUser = testFactory.getStudentUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake__c sitBefore = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBefore), sitApplicationFieldsNotEmptyErrorMsg(sitBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_APPROVED, null, con.Id);
            insert ipa;

            reduivy__Study_Intake__c sitAfter = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitAfter), sitApplicationFieldsNotEmptyErrorMsg(sitAfter));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testAsStudent to update ipa from submitted to approved, linking Study Intake during update
     */
    @IsTest
    static void testAsStudent_UpdateIpa_SubmittedToApproved_NoStudyIntakeToWithStudyIntake() {
        User studentUser = testFactory.getStudentUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake__c sit = querySit(KEY_CYINTAKE);

            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_SUBMITTED, null, con.Id);
            insert ipa;

            reduivy__Study_Intake__c sitBeforeUpdate = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitBeforeUpdate), sitApplicationFieldsNotEmptyErrorMsg(sitBeforeUpdate));

            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;
            ipa.reduivy__Study_Intake__c = sit.Id;
            update ipa;

            reduivy__Study_Intake__c sitAfterUpdate = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(1, sitAfterUpdate.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sitAfterUpdate.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdate, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Expected: 0; Actual: ' + sitAfterUpdate.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdate, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Expected: 0; Actual: ' + sitAfterUpdate.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdate, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Expected: 0; Actual: ' + sitAfterUpdate.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdate, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Expected: 0; Actual: ' + sitAfterUpdate.get(FIELD_BOOKED_PLACES));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testAsStudent to update ipa from submitted to approved, removing Study Intake during update
     */
    @IsTest
    static void testAsStudent_UpdateIpa_SubmittedToApproved_WithStudyIntakeToNoStudyIntake() {
        User studentUser = testFactory.getStudentUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake__c sit = querySit(KEY_CYINTAKE);

            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sit.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake__c sitBeforeUpdate = querySit(KEY_CYINTAKE);
            System.Assert.areEqual(1, sitBeforeUpdate.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdate, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications! Expected: 0; Actual: ' + sitBeforeUpdate.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdate, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Expected: 0; Actual: ' + sitBeforeUpdate.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdate, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Expected: 0; Actual: ' + sitBeforeUpdate.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdate, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Expected: 0; Actual: ' + sitBeforeUpdate.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdate, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Expected: 0; Actual: ' + sitBeforeUpdate.get(FIELD_BOOKED_PLACES));

            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;
            ipa.reduivy__Study_Intake__c = null;
            update ipa;

            reduivy__Study_Intake__c sitAfterUpdate = querySit(KEY_CYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sitAfterUpdate), sitApplicationFieldsNotEmptyErrorMsg(sitAfterUpdate));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testAsStudent to update ipa from submitted to approved, and changing Study Intake during update
     */
    @IsTest
    static void testAsStudent_UpdateIpa_SubmittedToApproved_StudyIntake1ToStudyIntake2() {
        User studentUser = testFactory.getStudentUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake__c sit1 = querySit(KEY_CYINTAKE);
            reduivy__Study_Intake__c sit2 = querySit(KEY_NYINTAKE);

            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sit1.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake__c sit1BeforeUpdate = querySit(KEY_CYINTAKE);
            reduivy__Study_Intake__c sit2BeforeUpdate = querySit(KEY_NYINTAKE);
            System.Assert.areEqual(1, sit1BeforeUpdate.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sit1BeforeUpdate, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications! Expected: 0; Actual: ' + sit1BeforeUpdate.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sit1BeforeUpdate, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Expected: 0; Actual: ' + sit1BeforeUpdate.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sit1BeforeUpdate, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Expected: 0; Actual: ' + sit1BeforeUpdate.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sit1BeforeUpdate, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Expected: 0; Actual: ' + sit1BeforeUpdate.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sit1BeforeUpdate, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Expected: 0; Actual: ' + sit1BeforeUpdate.get(FIELD_BOOKED_PLACES));

            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sit2BeforeUpdate), sitApplicationFieldsNotEmptyErrorMsg(sit2BeforeUpdate));

            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;
            ipa.reduivy__Study_Intake__c = sit2.Id;
            update ipa;

            reduivy__Study_Intake__c sit1AfterUpdate = querySit(KEY_CYINTAKE);
            reduivy__Study_Intake__c sit2AfterUpdate = querySit(KEY_NYINTAKE);
            System.Assert.isTrue(sitApplicationFieldsAreEmpty(sit1AfterUpdate), sitApplicationFieldsNotEmptyErrorMsg(sit1AfterUpdate));
            System.Assert.areEqual(1, sit2AfterUpdate.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sit2AfterUpdate.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.isTrue(sitFieldIsEmpty(sit2AfterUpdate, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Expected: 0; Actual: ' + sit2AfterUpdate.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sit2AfterUpdate, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Expected: 0; Actual: ' + sit2AfterUpdate.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sit2AfterUpdate, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Expected: 0; Actual: ' + sit2AfterUpdate.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sitFieldIsEmpty(sit2AfterUpdate, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Expected: 0; Actual: ' + sit2AfterUpdate.get(FIELD_BOOKED_PLACES));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    @IsTest
    static void testAsStudent_UpdateIpa_OfferToAccepted_Full() {
        User studentUser = testFactory.getStudentUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        
        reduivy__Study_Intake__c sitBeforeInsertIpa = querySit(KEY_CYINTAKE);
        List<reduivy__Individual_Program_Application__c> ipaList = new List<reduivy__Individual_Program_Application__c>();

        for(Integer i = 0; i < STUDY_INTAKE_CAPACITY + 1; i++){
            reduivy__Individual_Program_Application__c ipa = newIpaWithSit(IPA_Helper.APPLICATION_STATUS_OFFER, sitBeforeInsertIpa.Id, con.Id);
            ipa.OwnerId = studentUser.Id;
            ipaList.add(ipa);
        }

        System.runAs(studentUser) {
            insert ipaList;
        }

        reduivy__Study_Intake__c sitBeforeUpdateIpa = querySit(KEY_CYINTAKE);
        System.Assert.areEqual(STUDY_INTAKE_CAPACITY + 1, sitBeforeUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before update!');
        System.Assert.areEqual(STUDY_INTAKE_CAPACITY + 1, sitBeforeUpdateIpa.reduivy__Approved_Applications__c, 'Wrong Approved Applications before update!');
        System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before update!');
        System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before update!');
        System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before update!');
        System.Assert.isTrue(sitFieldIsEmpty(sitBeforeUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places before update!');
        
        for(Integer i = 0; i < STUDY_INTAKE_CAPACITY; i++) {
            ipaList[i].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;
        }

        System.runAs(studentUser) {
            update ipaList;
        }

        reduivy__Study_Intake__c sitAfterUpdate10Ipa = querySit(KEY_CYINTAKE);
        System.Assert.areEqual(STUDY_INTAKE_CAPACITY + 1, sitAfterUpdate10Ipa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
        System.Assert.areEqual(STUDY_INTAKE_CAPACITY + 1, sitAfterUpdate10Ipa.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
        System.Assert.areEqual(STUDY_INTAKE_CAPACITY, sitAfterUpdate10Ipa.reduivy__Accepted_Applications__c, 'Wrong Accepted Applications!');
        System.Assert.areEqual(STUDY_INTAKE_CAPACITY, sitAfterUpdate10Ipa.reduivy__Booked_Places__c, 'Wrong Booked Places!');
        System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdate10Ipa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications!');
        System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdate10Ipa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications!');

        ipaList[STUDY_INTAKE_CAPACITY].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;

        System.runAs(studentUser) {
            try{
                update ipaList[STUDY_INTAKE_CAPACITY];
                System.Assert.fail('Should be failed as the available places is 0! reduivy__Available_Places__c: ' + sitAfterUpdate10Ipa.reduivy__Available_Places__c);
            } catch(Exception exp) {
                String errorMsg = String.format(Label.Error_No_Available_Places_Remaining_In_Study_Intake, new List<String> {
                    SIT_Helper.getObjectLabel(), sitAfterUpdate10Ipa.Name
                });
                System.Assert.isTrue(exp.getMessage().contains(errorMsg), 'Wrong error message! Expected: ' + errorMsg + ', Actual: ' + exp.getMessage());
            }
        }
        
        reduivy__Study_Intake__c sitAfterUpdate1Ipa = querySit(KEY_CYINTAKE);
        System.Assert.areEqual(STUDY_INTAKE_CAPACITY + 1, sitAfterUpdate1Ipa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
        System.Assert.areEqual(STUDY_INTAKE_CAPACITY + 1, sitAfterUpdate1Ipa.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
        System.Assert.areEqual(STUDY_INTAKE_CAPACITY, sitAfterUpdate1Ipa.reduivy__Accepted_Applications__c, 'Wrong Accepted Applications!');
        System.Assert.areEqual(STUDY_INTAKE_CAPACITY, sitAfterUpdate1Ipa.reduivy__Booked_Places__c, 'Wrong Booked Places!');
        System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdate1Ipa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications!');
        System.Assert.isTrue(sitFieldIsEmpty(sitAfterUpdate1Ipa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications!');

        
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    
    /**
     * @description Test inserting 10 IPA with random statuses, updating 5 IPA, and asserting Study Intake rollups.
     */
    @IsTest
    static void testAsStudent_InsertAndUpdateMultipleIpaStatuses() {
        User studentUser = testFactory.getStudentUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        System.runAs(studentUser) {
            Contact con = getCon();
            reduivy__Study_Intake__c sit = querySit(KEY_CYINTAKE);
            
            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>{
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_DRAFT, sit.Id, con.Id),        // 0
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sit.Id, con.Id),    // 1
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REVIEWING, sit.Id, con.Id),     // 2
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_APPROVED, sit.Id, con.Id),      // 3
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_OFFER, sit.Id, con.Id),         // 4
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REJECTED, sit.Id, con.Id),      // 5
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sit.Id, con.Id),     // 6
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REVIEWING, sit.Id, con.Id),     // 7
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_CANCELLED, sit.Id, con.Id),     // 8
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_APPROVED, sit.Id, con.Id)       // 9
            };
            insert ipas;
            
            reduivy__Study_Intake__c sitAfterInsert = querySit(KEY_CYINTAKE);
            
            System.Assert.areEqual(8, sitAfterInsert.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after insert');
            System.Assert.areEqual(3, sitAfterInsert.reduivy__Approved_Applications__c, 'Approved Applications wrong after insert');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterInsert, FIELD_ACCEPTED_APPLICATIONS), 'Accepted Applications should be empty, actual: ' + sitAfterInsert.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.areEqual(1, sitAfterInsert.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after insert');
            System.Assert.areEqual(2, sitAfterInsert.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after insert');
            System.Assert.areEqual(
                sitAfterInsert.reduivy__Accepted_Applications__c, 
                sitAfterInsert.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after insert'
            );
            
            // Now update 5 of the IPAs
            ipas[1].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING;       // Submitted -> Reviewing
            ipas[2].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;        // Reviewing -> Approved
            ipas[4].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;  // Offer -> Offer Accepted
            ipas[7].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;        // Reviewing -> Approved
            ipas[8].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_CANCELLED;       // Cancelled -> Cancelled (still no rollup)
            update ipas;
            
            reduivy__Study_Intake__c sitAfterUpdate = querySit(KEY_CYINTAKE);
            
            System.Assert.areEqual(8, sitAfterUpdate.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after update');
            System.Assert.areEqual(5, sitAfterUpdate.reduivy__Approved_Applications__c, 'Approved Applications wrong after update');
            System.Assert.areEqual(1, sitAfterUpdate.reduivy__Accepted_Applications__c, 'Accepted Applications wrong after update');
            System.Assert.areEqual(1, sitAfterUpdate.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after update');
            System.Assert.areEqual(1, sitAfterUpdate.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after update');
            System.Assert.areEqual(
                sitAfterUpdate.reduivy__Accepted_Applications__c, 
                sitAfterUpdate.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after update'
            );
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description Test inserting 10 IPA with random statuses, updating 5 IPA, and asserting Study Intake rollups.
     */
    @IsTest
    static void testAsStudent_InsertAndUpdateMultipleIpaStatuses_2() {
        User studentUser = testFactory.getStudentUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        System.runAs(studentUser) {
            Contact con = getCon();
            reduivy__Study_Intake__c sit = querySit(KEY_CYINTAKE);
            
            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>{
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sit.Id, con.Id),    // 0
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sit.Id, con.Id),    // 1
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REVIEWING, sit.Id, con.Id),     // 2
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_APPROVED, sit.Id, con.Id),      // 3
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_APPROVED, sit.Id, con.Id),      // 4
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REJECTED, sit.Id, con.Id),      // 5
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REJECTED, sit.Id, con.Id),      // 6
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REVIEWING, sit.Id, con.Id),     // 7
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_CANCELLED, sit.Id, con.Id),     // 8
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_DRAFT, sit.Id, con.Id)          // 9
            };
            insert ipas;
            
            reduivy__Study_Intake__c sitAfterInsert = querySit(KEY_CYINTAKE);
            
            System.Assert.areEqual(8, sitAfterInsert.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after insert');
            System.Assert.areEqual(2, sitAfterInsert.reduivy__Approved_Applications__c, 'Approved Applications wrong after insert');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterInsert, FIELD_ACCEPTED_APPLICATIONS), 'Accepted Applications should be empty, actual: ' + sitAfterInsert.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.areEqual(2, sitAfterInsert.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after insert');
            System.Assert.areEqual(2, sitAfterInsert.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after insert');
            System.Assert.areEqual(
                sitAfterInsert.reduivy__Accepted_Applications__c, 
                sitAfterInsert.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after insert'
            );
            
            // Update
            ipas[0].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING;       // Submitted -> Reviewing
            ipas[2].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;        // Reviewing -> Approved
            ipas[4].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;  // Approved -> Offer Accepted
            ipas[6].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_CANCELLED;       // Rejected -> Cancelled
            ipas[9].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_CANCELLED;       // Draft -> Cancelled
            update ipas;
            
            reduivy__Study_Intake__c sitAfterUpdate = querySit(KEY_CYINTAKE);
            
            System.Assert.areEqual(7, sitAfterUpdate.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after update');
            System.Assert.areEqual(3, sitAfterUpdate.reduivy__Approved_Applications__c, 'Approved Applications wrong after update');
            System.Assert.areEqual(1, sitAfterUpdate.reduivy__Accepted_Applications__c, 'Accepted Applications wrong after update');
            System.Assert.areEqual(1, sitAfterUpdate.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after update');
            System.Assert.areEqual(2, sitAfterUpdate.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after update');
            System.Assert.areEqual(
                sitAfterUpdate.reduivy__Accepted_Applications__c, 
                sitAfterUpdate.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after update'
            );
                 
            
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }


    /**
     * @description Test inserting 10 IPA with random statuses, updating 5 IPA, and asserting Study Intake rollups.
     */
    @IsTest
    static void testAsStudent_InsertAndUpdateMultipleIpaStatuses_3() {
        User studentUser = testFactory.getStudentUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        System.runAs(studentUser) {
            Contact con = getCon();
            reduivy__Study_Intake__c sit = querySit(KEY_CYINTAKE);
            
            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>{
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_DRAFT, sit.Id, con.Id),           // 0
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sit.Id, con.Id),       // 1
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sit.Id, con.Id),       // 2
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REVIEWING, sit.Id, con.Id),        // 3
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_APPROVED, sit.Id, con.Id),         // 4
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REJECTED, sit.Id, con.Id),         // 5
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REJECTED, sit.Id, con.Id),         // 6
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REVIEWING, sit.Id, con.Id),        // 7
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_CANCELLED, sit.Id, con.Id),        // 8
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_APPROVED, sit.Id, con.Id)          // 9
            };
            insert ipas;
            
            reduivy__Study_Intake__c sitAfterInsert = querySit(KEY_CYINTAKE);
            
            System.Assert.areEqual(8, sitAfterInsert.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after insert');
            System.Assert.areEqual(2, sitAfterInsert.reduivy__Approved_Applications__c, 'Approved Applications wrong after insert');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterInsert, FIELD_ACCEPTED_APPLICATIONS), 'Accepted Applications should be empty, actual: ' + sitAfterInsert.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.areEqual(2, sitAfterInsert.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after insert');
            System.Assert.areEqual(2, sitAfterInsert.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after insert');
            System.Assert.areEqual(
                sitAfterInsert.reduivy__Accepted_Applications__c, 
                sitAfterInsert.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after insert'
            );
            
            // Update
            ipas[1].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING;        // Submitted -> Reviewing
            ipas[2].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING;        // Submitted -> Reviewing
            ipas[4].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;   // Approved -> Offer Accepted
            ipas[5].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_CANCELLED;        // Rejected -> Cancelled
            ipas[7].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;         // Reviewing -> Approved
            update ipas;
            
            reduivy__Study_Intake__c sitAfterUpdate = querySit(KEY_CYINTAKE);
            
            System.Assert.areEqual(7, sitAfterUpdate.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after update');
            System.Assert.areEqual(3, sitAfterUpdate.reduivy__Approved_Applications__c, 'Approved Applications wrong after update');
            System.Assert.areEqual(1, sitAfterUpdate.reduivy__Accepted_Applications__c, 'Accepted Applications wrong after update');
            System.Assert.areEqual(1, sitAfterUpdate.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after update');
            System.Assert.areEqual(3, sitAfterUpdate.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after update');
            System.Assert.areEqual(
                sitAfterUpdate.reduivy__Accepted_Applications__c, 
                sitAfterUpdate.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after update'
            );
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description Test inserting 10 IPA with random statuses, updating 5 IPA, and asserting Study Intake rollups.
     */
    @IsTest
    static void testAsStudent_InsertAndUpdateMultipleIpaStatuses_4() {
        User studentUser = testFactory.getStudentUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        System.runAs(studentUser) {
            Contact con = getCon();
            reduivy__Study_Intake__c sit = querySit(KEY_CYINTAKE);
            
            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>{
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_DRAFT, sit.Id, con.Id),           // 0
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sit.Id, con.Id),       // 1
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sit.Id, con.Id),       // 2
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REVIEWING, sit.Id, con.Id),        // 3
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_APPROVED, sit.Id, con.Id),         // 4
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REJECTED, sit.Id, con.Id),         // 5
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REJECTED, sit.Id, con.Id),         // 6
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REVIEWING, sit.Id, con.Id),        // 7
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_CANCELLED, sit.Id, con.Id),        // 8
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_APPROVED, sit.Id, con.Id)          // 9
            };
            insert ipas;
            
            reduivy__Study_Intake__c sitAfterInsert = querySit(KEY_CYINTAKE);
            
            System.Assert.areEqual(8, sitAfterInsert.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after insert');
            System.Assert.areEqual(2, sitAfterInsert.reduivy__Approved_Applications__c, 'Approved Applications wrong after insert');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterInsert, FIELD_ACCEPTED_APPLICATIONS), 'Accepted Applications should be empty, actual: ' + sitAfterInsert.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.areEqual(2, sitAfterInsert.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after insert');
            System.Assert.areEqual(2, sitAfterInsert.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after insert');
            System.Assert.areEqual(
                sitAfterInsert.reduivy__Accepted_Applications__c, 
                sitAfterInsert.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after insert'
            );
            
            // Update
            ipas[1].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING;        // Submitted -> Reviewing
            ipas[2].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REJECTED;         // Submitted -> Rejected
            ipas[4].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;   // Approved -> Offer Accepted
            ipas[5].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_CANCELLED;        // Rejected -> Cancelled
            ipas[7].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;         // Reviewing -> Approved
            update ipas;
            
            reduivy__Study_Intake__c sitAfterUpdate = querySit(KEY_CYINTAKE);
            
            System.Assert.areEqual(7, sitAfterUpdate.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after update');
            System.Assert.areEqual(3, sitAfterUpdate.reduivy__Approved_Applications__c, 'Approved Applications wrong after update');
            System.Assert.areEqual(1, sitAfterUpdate.reduivy__Accepted_Applications__c, 'Accepted Applications wrong after update');
            System.Assert.areEqual(2, sitAfterUpdate.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after update');
            System.Assert.areEqual(2, sitAfterUpdate.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after update');
            System.Assert.areEqual(
                sitAfterUpdate.reduivy__Accepted_Applications__c, 
                sitAfterUpdate.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after update'
            );
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description Test inserting 10 IPA with random statuses, updating 5 IPA, and asserting Study Intake rollups.
     */
    @IsTest
    static void testAsStudent_InsertAndUpdateMultipleIpaStatuses_5() {
        User studentUser = testFactory.getStudentUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        System.runAs(studentUser) {
            Contact con = getCon();
            reduivy__Study_Intake__c sit = querySit(KEY_CYINTAKE);
            
            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>{
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_DRAFT, sit.Id, con.Id),           // 0
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sit.Id, con.Id),       // 1
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REVIEWING, sit.Id, con.Id),        // 2
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_APPROVED, sit.Id, con.Id),         // 3
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_OFFER, sit.Id, con.Id),            // 4
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REJECTED, sit.Id, con.Id),         // 5
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REVIEWING, sit.Id, con.Id),        // 6
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_APPROVED, sit.Id, con.Id),         // 7
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_CANCELLED, sit.Id, con.Id),        // 8
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REJECTED, sit.Id, con.Id)          // 9
            };
            insert ipas;
            
            reduivy__Study_Intake__c sitAfterInsert = querySit(KEY_CYINTAKE);
            
            System.Assert.areEqual(8, sitAfterInsert.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after insert');
            System.Assert.areEqual(3, sitAfterInsert.reduivy__Approved_Applications__c, 'Approved Applications wrong after insert');
            System.Assert.isTrue(sitFieldIsEmpty(sitAfterInsert, FIELD_ACCEPTED_APPLICATIONS), 'Accepted Applications should be empty, actual: ' + sitAfterInsert.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.areEqual(2, sitAfterInsert.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after insert');
            System.Assert.areEqual(2, sitAfterInsert.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after insert');
            System.Assert.areEqual(
                sitAfterInsert.reduivy__Accepted_Applications__c, 
                sitAfterInsert.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after insert'
            );
            
            // Update
            ipas[1].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING;        // Submitted -> Reviewing
            ipas[2].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;         // Reviewing -> Approved
            ipas[4].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;   // Offer -> Offer Accepted
            ipas[5].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_CANCELLED;        // Rejected -> Cancelled
            ipas[7].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REJECTED;         // Approved -> Rejected
            update ipas;
            
            reduivy__Study_Intake__c sitAfterUpdate = querySit(KEY_CYINTAKE);
            
            System.Assert.areEqual(7, sitAfterUpdate.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after update');
            System.Assert.areEqual(3, sitAfterUpdate.reduivy__Approved_Applications__c, 'Approved Applications wrong after update');
            System.Assert.areEqual(1, sitAfterUpdate.reduivy__Accepted_Applications__c, 'Accepted Applications wrong after update');
            System.Assert.areEqual(2, sitAfterUpdate.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after update');
            System.Assert.areEqual(2, sitAfterUpdate.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after update');
            System.Assert.areEqual(
                sitAfterUpdate.reduivy__Accepted_Applications__c, 
                sitAfterUpdate.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after update'
            );
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }


    /**
     * @description Test inserting 10 IPA with random statuses, updating 5 IPA, and asserting Study Intake rollups. Over capacity is tested
     */
    @IsTest
    static void testAsStudent_InsertAndUpdateMultipleIpaStatuses_OverCapacity() {
        User studentUser = testFactory.getStudentUser();
        setEnableSigSetting(false);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        System.runAs(studentUser) {
            Contact con = getCon();
            reduivy__Study_Intake__c sit = querySit(KEY_CYINTAKE);
            
            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>{
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_DRAFT, sit.Id, con.Id),           // 0
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sit.Id, con.Id),       // 1
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REVIEWING, sit.Id, con.Id),        // 2
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED, sit.Id, con.Id),   // 3
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_APPROVED, sit.Id, con.Id),         // 4
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_APPROVED, sit.Id, con.Id),         // 5
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REVIEWING, sit.Id, con.Id),        // 6
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_APPROVED, sit.Id, con.Id),         // 7
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_CANCELLED, sit.Id, con.Id),        // 8
                newIpaWithSit(IPA_Helper.APPLICATION_STATUS_REJECTED, sit.Id, con.Id)          // 9
            };
            insert ipas;
            
            reduivy__Study_Intake__c sitAfterInsert = querySit(KEY_CYINTAKE);
            
            System.Assert.areEqual(8, sitAfterInsert.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after insert');
            System.Assert.areEqual(4, sitAfterInsert.reduivy__Approved_Applications__c, 'Approved Applications wrong after insert');
            System.Assert.areEqual(1, sitAfterInsert.reduivy__Accepted_Applications__c, 'Accepted Applications wrong after insert');
            System.Assert.areEqual(1, sitAfterInsert.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after insert');
            System.Assert.areEqual(2, sitAfterInsert.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after insert');
            System.Assert.areEqual(
                sitAfterInsert.reduivy__Accepted_Applications__c, 
                sitAfterInsert.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after insert'
            );
            
            // Update
            ipas[1].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;        // Submitted -> Reviewing
            ipas[2].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;         // Reviewing -> Approved
            ipas[4].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;      // Offer -> Offer Accepted
            ipas[5].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;        // Rejected -> Cancelled
            ipas[7].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;         // Approved -> Rejected

            try{
                update ipas;
                System.Assert.fail('Should be failed as the booked places is full! Booked Places: ' + sitAfterInsert.reduivy__Booked_Places__c);
            } catch(Exception exp) {
                String errorMsg = String.format(Label.Error_No_Available_Places_Remaining_In_Study_Intake, new List<String> {
                    SIT_Helper.getObjectLabel(), sitAfterInsert.Name
                });

                System.Assert.isTrue(exp.getMessage().contains(errorMsg), 'Wrong error message! Expected: ' + errorMsg + ', Actual: ' + exp.getMessage());
                
            }
            
            reduivy__Study_Intake__c sitAfterUpdate = querySit(KEY_CYINTAKE);
            
            System.Assert.areEqual(8, sitAfterUpdate.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after insert');
            System.Assert.areEqual(4, sitAfterUpdate.reduivy__Approved_Applications__c, 'Approved Applications wrong after insert');
            System.Assert.areEqual(1, sitAfterUpdate.reduivy__Accepted_Applications__c, 'Accepted Applications wrong after insert');
            System.Assert.areEqual(1, sitAfterUpdate.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after insert');
            System.Assert.areEqual(2, sitAfterUpdate.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after insert');
            System.Assert.areEqual(
                sitAfterUpdate.reduivy__Accepted_Applications__c, 
                sitAfterUpdate.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after insert'
            );
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }


    //=============Study intake group=========================


    /**
     * @description test as admin, create approved ipa
     */
    @IsTest
    static void testSigAsAdmin_CreateIpa_Approved() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake_Group__c sigBefore = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBefore), sigApplicationFieldsNotEmptyErrorMsg(sigBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sigBefore.Id, con.Id);
            insert ipa;
            
            reduivy__Study_Intake_Group__c sigAfter = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigAfter.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sigAfter.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Excepted: 0; Actual: ' + sigAfter.get(FIELD_BOOKED_PLACES));

        }
        
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description test as admin, create offer ipa
     */
    @IsTest
    static void testSigAsAdmin_CreateIpa_Offer() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake_Group__c sigBefore = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBefore), sigApplicationFieldsNotEmptyErrorMsg(sigBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_OFFER, sigBefore.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigAfter = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigAfter.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sigAfter.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Excepted: 0; Actual: ' + sigAfter.get(FIELD_BOOKED_PLACES));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description test as admin, create offer accepted ipa
     */
    @IsTest
    static void testSigAsAdmin_CreateIpa_OfferAccepted() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        setEnableSigSetting(true);

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake_Group__c sigBefore = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBefore), sigApplicationFieldsNotEmptyErrorMsg(sigBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED, sigBefore.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigAfter = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigAfter.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sigAfter.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.areEqual(1, sigAfter.reduivy__Accepted_Applications__c, 'Wrong Accepted Applications!');
            System.Assert.areEqual(1, sigAfter.reduivy__Booked_Places__c, 'Wrong Booked Places!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_REVIEWING_APPLICATIONS));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description test as admin, create offer declined ipa
     */
    @IsTest
    static void testSigAsAdmin_CreateIpa_OfferDeclined() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake_Group__c sigBefore = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBefore), sigApplicationFieldsNotEmptyErrorMsg(sigBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_OFFER_DECLINED, sigBefore.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigAfter = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigAfter.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sigAfter.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Excepted: 0; Actual: ' + sigAfter.get(FIELD_BOOKED_PLACES));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description test as admin, create rejected ipa
     */
    @IsTest
    static void testSigAsAdmin_CreateIpa_Rejected() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake_Group__c sigBefore = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBefore), sigApplicationFieldsNotEmptyErrorMsg(sigBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REJECTED, sigBefore.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigAfter = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigAfter.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sigAfter.reduivy__Rejected_Applications__c, 'Wrong Rejected Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Excepted: 0; Actual: ' + sigAfter.get(FIELD_BOOKED_PLACES));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description test as admin, create reviewing ipa
     */
    @IsTest
    static void testSigAsAdmin_CreateIpa_Reviewing() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake_Group__c sigBefore = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBefore), sigApplicationFieldsNotEmptyErrorMsg(sigBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REVIEWING, sigBefore.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigAfter = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigAfter.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sigAfter.reduivy__Reviewing_Applications__c, 'Wrong Reviewing Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Excepted: 0; Actual: ' + sigAfter.get(FIELD_BOOKED_PLACES));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description test as admin, create reviewing awaiting docs ipa
     */
    @IsTest
    static void testSigAsAdmin_CreateIpa_ReviewingAwaitingDocs() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake_Group__c sigBefore = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBefore), sigApplicationFieldsNotEmptyErrorMsg(sigBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(APPLICATION_STATUS_REVIEWING_AWAITING_DOCS, sigBefore.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigAfter = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigAfter.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sigAfter.reduivy__Reviewing_Applications__c, 'Wrong Reviewing Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Excepted: 0; Actual: ' + sigAfter.get(FIELD_BOOKED_PLACES));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description test as admin, create submitted ipa
     */
    @IsTest
    static void testSigAsAdmin_CreateIpa_Submitted() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake_Group__c sigBefore = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBefore), sigApplicationFieldsNotEmptyErrorMsg(sigBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sigBefore.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigAfter = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigAfter.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Excepted: 0; Actual: ' + sigAfter.get(FIELD_BOOKED_PLACES));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description test as admin, create draft ipa
     */
    @IsTest
    static void testSigAsAdmin_CreateIpa_Draft() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake_Group__c sigBefore = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBefore), sigApplicationFieldsNotEmptyErrorMsg(sigBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_DRAFT, sigBefore.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigAfter = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigAfter), sigApplicationFieldsNotEmptyErrorMsg(sigAfter));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description test as admin, create cancelled ipa
     */
    @IsTest
    static void testSigAsAdmin_CreateIpa_Cancelled() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake_Group__c sigBefore = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBefore), sigApplicationFieldsNotEmptyErrorMsg(sigBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_CANCELLED, sigBefore.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigAfter = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigAfter), sigApplicationFieldsNotEmptyErrorMsg(sigAfter));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testSigAsAdmin to update ipa from draft to submitted
     */
    @IsTest
    static void testSigAsAdmin_UpdateIpa_DraftToSubmitted() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake_Group__c sigBeforeInsertIpa = querySig(KEY_SIGSTANDARD);
            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_DRAFT, sigBeforeInsertIpa.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigBeforeUpdateIpa = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBeforeUpdateIpa), sigApplicationFieldsNotEmptyErrorMsg(sigBeforeUpdateIpa));

            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_SUBMITTED;
            update ipa;

            reduivy__Study_Intake_Group__c sigAfterUpdateIpa = querySig(KEY_SIGSTANDARD);

            System.Assert.areEqual(1, sigAfterUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications! Excepted: 0; Actual: ' + sigAfterUpdateIpa.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Excepted: 0; Actual: ' + sigAfterUpdateIpa.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Excepted: 0; Actual: ' + sigAfterUpdateIpa.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Excepted: 0; Actual: ' + sigAfterUpdateIpa.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Excepted: 0; Actual: ' + sigAfterUpdateIpa.get(FIELD_BOOKED_PLACES));
            
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    @IsTest
    static void testSigAsAdmin_UpdateIpa_SubmittedToReviewing() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake_Group__c sigBeforeInsertIpa = querySig(KEY_SIGSTANDARD);
            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sigBeforeInsertIpa.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigBeforeUpdateIpa = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigBeforeUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places before update!');

            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING;
            update ipa;

            reduivy__Study_Intake_Group__c sigAfterUpdateIpa = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigAfterUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sigAfterUpdateIpa.reduivy__Reviewing_Applications__c, 'Wrong Reviewing Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places!');
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    @IsTest
    static void testSigAsAdmin_UpdateIpa_ReviewingToApproved() {
        User ADMIN_USER = testFactory.getReduAdminUser();
    
        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake_Group__c sigBeforeInsertIpa = querySig(KEY_SIGSTANDARD);
            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REVIEWING, sigBeforeInsertIpa.Id, con.Id);
            insert ipa;
    
            reduivy__Study_Intake_Group__c sigBeforeUpdateIpa = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigBeforeUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before update!');
            System.Assert.areEqual(1, sigBeforeUpdateIpa.reduivy__Reviewing_Applications__c, 'Wrong Reviewing Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places before update!');
    
            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;
            update ipa;
    
            reduivy__Study_Intake_Group__c sigAfterUpdateIpa = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigAfterUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sigAfterUpdateIpa.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places!');
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }
    
    @IsTest
    static void testSigAsAdmin_UpdateIpa_ApprovedToOffer() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake_Group__c sigBeforeInsertIpa = querySig(KEY_SIGSTANDARD);
            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sigBeforeInsertIpa.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigBeforeUpdateIpa = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigBeforeUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before update!');
            System.Assert.areEqual(1, sigBeforeUpdateIpa.reduivy__Approved_Applications__c, 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places before update!');

            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER;
            update ipa;

            reduivy__Study_Intake_Group__c sigAfterUpdateIpa = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigAfterUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sigAfterUpdateIpa.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places!');
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    @IsTest
    static void testSigAsAdmin_UpdateIpa_OfferToAccepted() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake_Group__c sigBeforeInsertIpa = querySig(KEY_SIGSTANDARD);
            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_OFFER, sigBeforeInsertIpa.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigBeforeUpdateIpa = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigBeforeUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before update!');
            System.Assert.areEqual(1, sigBeforeUpdateIpa.reduivy__Approved_Applications__c, 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places before update!');

            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;
            update ipa;

            reduivy__Study_Intake_Group__c sigAfterUpdateIpa = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigAfterUpdateIpa.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.areEqual(1, sigAfterUpdateIpa.reduivy__Accepted_Applications__c, 'Wrong Accepted Applications!');
            System.Assert.areEqual(1, sigAfterUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sigAfterUpdateIpa.reduivy__Booked_Places__c, 'Wrong Booked Places!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications!');

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    @IsTest
    static void testSigAsAdmin_UpdateIpa_OfferToDeclined() {
        User ADMIN_USER = testFactory.getReduAdminUser();
    
        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake_Group__c sigBeforeInsertIpa = querySig(KEY_SIGSTANDARD);
            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_OFFER, sigBeforeInsertIpa.Id, con.Id);
            insert ipa;
    
            reduivy__Study_Intake_Group__c sigBeforeUpdateIpa = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigBeforeUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before update!');
            System.Assert.areEqual(1, sigBeforeUpdateIpa.reduivy__Approved_Applications__c, 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places before update!');
    
            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_DECLINED;
            update ipa;
    
            reduivy__Study_Intake_Group__c sigAfterUpdateIpa = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigAfterUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sigBeforeUpdateIpa.reduivy__Approved_Applications__c, 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places!');
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }
    
    @IsTest
    static void testSigAsAdmin_UpdateIpa_ReviewingToRejected() {
        User ADMIN_USER = testFactory.getReduAdminUser();
    
        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake_Group__c sigBeforeInsertIpa = querySig(KEY_SIGSTANDARD);
            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REVIEWING, sigBeforeInsertIpa.Id, con.Id);
            insert ipa;
    
            reduivy__Study_Intake_Group__c sigBeforeUpdateIpa = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigBeforeUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before update!');
            System.Assert.areEqual(1, sigBeforeUpdateIpa.reduivy__Reviewing_Applications__c, 'Wrong Reviewing Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places before update!');
    
            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REJECTED;
            update ipa;
    
            reduivy__Study_Intake_Group__c sigAfterUpdateIpa = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigAfterUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sigAfterUpdateIpa.reduivy__Rejected_Applications__c, 'Wrong Rejected Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places!');
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    @IsTest
    static void testSigAsAdmin_UpdateIpa_SubmittedToCancelled() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake_Group__c sigBeforeInsertIpa = querySig(KEY_SIGSTANDARD);
            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sigBeforeInsertIpa.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigBeforeUpdateIpa = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigBeforeUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places before update!');

            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_CANCELLED;
            update ipa;

            reduivy__Study_Intake_Group__c sigAfterUpdateIpa = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigAfterUpdateIpa), sigApplicationFieldsNotEmptyErrorMsg(sigAfterUpdateIpa));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testSigAsAdmin to delete and undelete IPA with status Submitted
     */
    @IsTest
    static void testSigAsAdmin_DeleteUndeleteIpa_Submitted() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake_Group__c sigBeforeInsert = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBeforeInsert), sigApplicationFieldsNotEmptyErrorMsg(sigBeforeInsert));

            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>();

            for (Integer i = 0; i < 5; i++) {
                ipas.add(newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sigBeforeInsert.Id, con.Id));
            }
            insert ipas;

            reduivy__Study_Intake_Group__c sigBeforeDelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(5, sigBeforeDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before delete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_BOOKED_PLACES));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_REVIEWING_APPLICATIONS));

            delete ipas[0];

            reduivy__Study_Intake_Group__c sigAfterDelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(4, sigAfterDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after delete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_BOOKED_PLACES));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_REVIEWING_APPLICATIONS));

            undelete ipas[0];

            reduivy__Study_Intake_Group__c sigAfterUndelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(5, sigAfterUndelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after undelete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_BOOKED_PLACES));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_REVIEWING_APPLICATIONS));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }


    /**
     * @description testSigAsAdmin to delete and undelete IPA with status Draft
     */
    @IsTest
    static void testSigAsAdmin_DeleteUndeleteIpa_Draft() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake_Group__c sigBeforeInsert = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBeforeInsert), sigApplicationFieldsNotEmptyErrorMsg(sigBeforeInsert));
            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>();

            for (Integer i = 0; i < 5; i++) {
                ipas.add(newIpaWithSig(IPA_Helper.APPLICATION_STATUS_DRAFT, sigBeforeInsert.Id, con.Id));
            }
            insert ipas;

            reduivy__Study_Intake_Group__c sigBeforeDelete = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBeforeDelete), sigApplicationFieldsNotEmptyErrorMsg(sigBeforeDelete));

            delete ipas[0];
            reduivy__Study_Intake_Group__c sigAfterDelete = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigAfterDelete), sigApplicationFieldsNotEmptyErrorMsg(sigAfterDelete));

            undelete ipas[0];
            reduivy__Study_Intake_Group__c sigAfterUndelete = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigAfterUndelete), sigApplicationFieldsNotEmptyErrorMsg(sigAfterUndelete));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testSigAsAdmin to delete and undelete IPA with status Reviewing
     */
    @IsTest
    static void testSigAsAdmin_DeleteUndeleteIpa_Reviewing() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake_Group__c sigBeforeInsert = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBeforeInsert), sigApplicationFieldsNotEmptyErrorMsg(sigBeforeInsert));

            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>();

            for (Integer i = 0; i < 5; i++) {
                ipas.add(newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REVIEWING, sigBeforeInsert.Id, con.Id));
            }
            insert ipas;

            reduivy__Study_Intake_Group__c sigBeforeDelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(5, sigBeforeDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before delete!');
            System.Assert.areEqual(5, sigBeforeDelete.reduivy__Reviewing_Applications__c, 'Wrong Reviewing Applications before delete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_BOOKED_PLACES));

            delete ipas[0];
            reduivy__Study_Intake_Group__c sigAfterDelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(4, sigAfterDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after delete!');
            System.Assert.areEqual(4, sigAfterDelete.reduivy__Reviewing_Applications__c, 'Wrong Reviewing Applications after delete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_BOOKED_PLACES));

            undelete ipas[0];
            reduivy__Study_Intake_Group__c sigAfterUndelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(5, sigAfterUndelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after undelete!');
            System.Assert.areEqual(5, sigAfterUndelete.reduivy__Reviewing_Applications__c, 'Wrong Reviewing Applications after undelete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_BOOKED_PLACES));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testSigAsAdmin to delete and undelete IPA with status Approved
     */
    @IsTest
    static void testSigAsAdmin_DeleteUndeleteIpa_Approved() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake_Group__c sigBeforeInsert = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBeforeInsert), sigApplicationFieldsNotEmptyErrorMsg(sigBeforeInsert));

            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>();

            for (Integer i = 0; i < 5; i++) {
                ipas.add(newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sigBeforeInsert.Id, con.Id));
            }
            insert ipas;

            reduivy__Study_Intake_Group__c sigBeforeDelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(5, sigBeforeDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before delete!');
            System.Assert.areEqual(5, sigBeforeDelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications before delete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_BOOKED_PLACES));

            delete ipas[0];
            reduivy__Study_Intake_Group__c sigAfterDelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(4, sigAfterDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after delete!');
            System.Assert.areEqual(4, sigAfterDelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications after delete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_BOOKED_PLACES));

            undelete ipas[0];
            reduivy__Study_Intake_Group__c sigAfterUndelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(5, sigAfterUndelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after undelete!');
            System.Assert.areEqual(5, sigAfterUndelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications after undelete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_BOOKED_PLACES));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testSigAsAdmin to delete and undelete IPA with status Offer
     */
    @IsTest
    static void testSigAsAdmin_DeleteUndeleteIpa_Offer() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake_Group__c sigBeforeInsert = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBeforeInsert), sigApplicationFieldsNotEmptyErrorMsg(sigBeforeInsert));

            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>();

            for (Integer i = 0; i < 5; i++) {
                ipas.add(newIpaWithSig(IPA_Helper.APPLICATION_STATUS_OFFER, sigBeforeInsert.Id, con.Id));
            }
            insert ipas;

            reduivy__Study_Intake_Group__c sigBeforeDelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(5, sigBeforeDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before delete!');
            System.Assert.areEqual(5, sigBeforeDelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications before delete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_BOOKED_PLACES));

            delete ipas[0];
            reduivy__Study_Intake_Group__c sigAfterDelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(4, sigAfterDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after delete!');
            System.Assert.areEqual(4, sigAfterDelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications after delete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_BOOKED_PLACES));

            undelete ipas[0];
            reduivy__Study_Intake_Group__c sigAfterUndelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(5, sigAfterUndelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after undelete!');
            System.Assert.areEqual(5, sigAfterUndelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications after undelete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_BOOKED_PLACES));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testSigAsAdmin to delete and undelete IPA with status Offer Accepted
     */
    @IsTest
    static void testSigAsAdmin_DeleteUndeleteIpa_OfferAccepted() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_CreateEnrollment_EXE'});


        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake_Group__c sigBeforeInsert = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBeforeInsert), sigApplicationFieldsNotEmptyErrorMsg(sigBeforeInsert));


            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>();

            for (Integer i = 0; i < 5; i++) {
                ipas.add(newIpaWithSig(IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED, sigBeforeInsert.Id, con.Id));
            }
            insert ipas;

            reduivy__Study_Intake_Group__c sigBeforeDelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(5, sigBeforeDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before delete!');
            System.Assert.areEqual(5, sigBeforeDelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications before delete!');
            System.Assert.areEqual(5, sigBeforeDelete.reduivy__Accepted_Applications__c, 'Wrong Accepted Applications before delete!');
            System.Assert.areEqual(5, sigBeforeDelete.reduivy__Booked_Places__c, 'Wrong Booked Places before delete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_REVIEWING_APPLICATIONS));

            delete ipas[0];
            reduivy__Study_Intake_Group__c sigAfterDelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(4, sigAfterDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after delete!');
            System.Assert.areEqual(4, sigAfterDelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications after delete!');
            System.Assert.areEqual(4, sigAfterDelete.reduivy__Accepted_Applications__c, 'Wrong Accepted Applications after delete!');
            System.Assert.areEqual(4, sigAfterDelete.reduivy__Booked_Places__c, 'Wrong Booked Places after delete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_REVIEWING_APPLICATIONS));

            undelete ipas[0];
            reduivy__Study_Intake_Group__c sigAfterUndelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(5, sigAfterUndelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after undelete!');
            System.Assert.areEqual(5, sigAfterUndelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications after undelete!');
            System.Assert.areEqual(5, sigAfterUndelete.reduivy__Accepted_Applications__c, 'Wrong Accepted Applications after undelete!');
            System.Assert.areEqual(5, sigAfterUndelete.reduivy__Booked_Places__c, 'Wrong Booked Places after delete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_REVIEWING_APPLICATIONS));
        }

        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_CreateEnrollment_EXE'});
    }


    /**
     * @description testSigAsAdmin to delete and undelete IPA with status Offer Declined
     */
    @IsTest
    static void testSigAsAdmin_DeleteUndeleteIpa_OfferDeclined() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake_Group__c sigBeforeInsert = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBeforeInsert), sigApplicationFieldsNotEmptyErrorMsg(sigBeforeInsert));

            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>();

            for (Integer i = 0; i < 5; i++) {
                ipas.add(newIpaWithSig(IPA_Helper.APPLICATION_STATUS_OFFER_DECLINED, sigBeforeInsert.Id, con.Id));
            }
            insert ipas;

            reduivy__Study_Intake_Group__c sigBeforeDelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(5, sigBeforeDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before delete!');
            System.Assert.areEqual(5, sigBeforeDelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications before delete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_BOOKED_PLACES));

            delete ipas[0];
            reduivy__Study_Intake_Group__c sigAfterDelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(4, sigAfterDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after delete!');
            System.Assert.areEqual(4, sigAfterDelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications after delete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_BOOKED_PLACES));

            undelete ipas[0];
            reduivy__Study_Intake_Group__c sigAfterUndelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(5, sigAfterUndelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after undelete!');
            System.Assert.areEqual(5, sigAfterUndelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications after undelete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_BOOKED_PLACES));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testSigAsAdmin to delete and undelete IPA with status Cancelled
     */
    @IsTest
    static void testSigAsAdmin_DeleteUndeleteIpa_Cancelled() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake_Group__c sigBeforeInsert = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBeforeInsert), sigApplicationFieldsNotEmptyErrorMsg(sigBeforeInsert));

            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>();

            for (Integer i = 0; i < 5; i++) {
                ipas.add(newIpaWithSig(IPA_Helper.APPLICATION_STATUS_CANCELLED, sigBeforeInsert.Id, con.Id));
            }
            insert ipas;

            reduivy__Study_Intake_Group__c sigBeforeDelete = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBeforeDelete), sigApplicationFieldsNotEmptyErrorMsg(sigBeforeDelete));

            delete ipas[0];
            reduivy__Study_Intake_Group__c sigAfterDelete = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigAfterDelete), sigApplicationFieldsNotEmptyErrorMsg(sigAfterDelete));

            undelete ipas[0];
            reduivy__Study_Intake_Group__c sigAfterUndelete = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigAfterUndelete), sigApplicationFieldsNotEmptyErrorMsg(sigAfterUndelete));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testSigAsAdmin to rollup to a nonexist field
     */
    @IsTest
    static void testSigAsAdmin_RollupFieldNotFound() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        IPA_Helper.isNegativeTests = true;

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake_Group__c sigBefore = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBefore), sigApplicationFieldsNotEmptyErrorMsg(sigBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_DRAFT, sigBefore.Id, con.Id);
            try{
                insert ipa;
                System.Assert.fail('Should be failed if reduivy__Rollup_Field_API_Name__c is not found!');
            } catch (Exception exp) {
                System.Assert.isTrue(
                    exp.getMessage().contains(getSigInvalidFieldErrorMessage()), 
                    'Wrong error message! Expected: ' + getSigInvalidFieldErrorMessage() + '; Actual: ' + exp.getMessage()
                );
            }

            reduivy__Study_Intake_Group__c sigAfter = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigAfter), sigApplicationFieldsNotEmptyErrorMsg(sigAfter));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testSigAsAdmin to rollup a nonexist ipa application status, no error should be thrown and will be simply ignored
     */
    @IsTest
    static void testSigAsAdmin_ApplicationStatusConfigNotFound() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        IPA_Helper.isNegativeTests = true;

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake_Group__c sigBefore = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBefore), sigApplicationFieldsNotEmptyErrorMsg(sigBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_CANCELLED, sigBefore.Id, con.Id);
            insert ipa;


            reduivy__Study_Intake_Group__c sigAfter = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigAfter), sigApplicationFieldsNotEmptyErrorMsg(sigAfter));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testSigAsAdmin to rollup to a date field
     */
    @IsTest
    static void testSigAsAdmin_RollupFieldIsNotNumber() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        IPA_Helper.isNegativeTests = true;

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake_Group__c sigBefore = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBefore), sigApplicationFieldsNotEmptyErrorMsg(sigBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sigBefore.Id, con.Id);
            try{
                insert ipa;
                System.Assert.fail('Should be failed if reduivy__Rollup_Field_API_Name__c is not number field!');
            } catch (Exception exp) {
                System.Assert.isTrue(
                    exp.getMessage().contains(getSigInvalidFieldErrorMessage()), 
                    'Wrong error message! Expected: ' + getSigInvalidFieldErrorMessage() + '; Actual: ' + exp.getMessage()
                );
            }

            reduivy__Study_Intake_Group__c sigAfter = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigAfter), sigApplicationFieldsNotEmptyErrorMsg(sigAfter));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testSigAsAdmin to rollup to a formula number field
     */
    @IsTest
    static void testSigAsAdmin_RollupFieldIsFormulaNumberField() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        IPA_Helper.isNegativeTests = true;

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake_Group__c sigBefore = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBefore), sigApplicationFieldsNotEmptyErrorMsg(sigBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sigBefore.Id, con.Id);
            try{
                insert ipa;
                System.Assert.fail('Should be failed if reduivy__Rollup_Field_API_Name__c is formula field!');
            } catch (Exception exp) {
                System.Assert.isTrue(
                    exp.getMessage().contains(getSigInvalidFieldErrorMessage()), 
                    'Wrong error message! Expected: ' + getSigInvalidFieldErrorMessage() + '; Actual: ' + exp.getMessage()
                );
            }

            reduivy__Study_Intake_Group__c sigAfter = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigAfter), sigApplicationFieldsNotEmptyErrorMsg(sigAfter));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    @Istest
    static void testSigAsAdmin_CreateIpa_Approved_NoStudyIntakeGroup(){
        User ADMIN_USER = testFactory.getReduAdminUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake_Group__c sigBefore = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBefore), sigApplicationFieldsNotEmptyErrorMsg(sigBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, null, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigAfter = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigAfter), sigApplicationFieldsNotEmptyErrorMsg(sigAfter));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testSigAsAdmin to update ipa from submitted to approved, linking Study Intake during update
     */
    @IsTest
    static void testSigAsAdmin_UpdateIpa_SubmittedToApproved_NoStudyIntakeGroupToWithStudyIntakeGroup() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake_Group__c sig = querySig(KEY_SIGSTANDARD);

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, null, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigBeforeUpdate = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBeforeUpdate), sigApplicationFieldsNotEmptyErrorMsg(sigBeforeUpdate));

            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;
            ipa.reduivy__Study_Intake_Group__c = sig.Id;
            update ipa;

            reduivy__Study_Intake_Group__c sigAfterUpdate = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigAfterUpdate.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sigAfterUpdate.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdate, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Expected: 0; Actual: ' + sigAfterUpdate.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdate, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Expected: 0; Actual: ' + sigAfterUpdate.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdate, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Expected: 0; Actual: ' + sigAfterUpdate.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdate, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Expected: 0; Actual: ' + sigAfterUpdate.get(FIELD_BOOKED_PLACES));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testSigAsAdmin to update ipa from submitted to approved, removing Study Intake during update
     */
    @IsTest
    static void testSigAsAdmin_UpdateIpa_SubmittedToApproved_WithStudyIntakeGroupToNoStudyIntakeGroup() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake_Group__c sig = querySig(KEY_SIGSTANDARD);

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sig.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigBeforeUpdate = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigBeforeUpdate.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdate, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications! Expected: 0; Actual: ' + sigBeforeUpdate.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdate, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Expected: 0; Actual: ' + sigBeforeUpdate.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdate, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Expected: 0; Actual: ' + sigBeforeUpdate.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdate, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Expected: 0; Actual: ' + sigBeforeUpdate.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdate, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Expected: 0; Actual: ' + sigBeforeUpdate.get(FIELD_BOOKED_PLACES));

            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;
            ipa.reduivy__Study_Intake_Group__c = null;
            update ipa;

            reduivy__Study_Intake_Group__c sigAfterUpdate = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigAfterUpdate), sigApplicationFieldsNotEmptyErrorMsg(sigAfterUpdate));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testSigAsAdmin to update ipa from submitted to approved, and changing Study Intake during update
     */
    @IsTest
    static void testSigAsAdmin_UpdateIpa_SubmittedToApproved_StudyIntakeGroup1ToStudyIntakeGroup2() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake_Group__c sig1 = querySig(KEY_SIGSTANDARD);
            reduivy__Study_Intake_Group__c sig2 = querySig(KEY_SIGDISABLED);

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sig1.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sig1BeforeUpdate = querySig(KEY_SIGSTANDARD);
            reduivy__Study_Intake_Group__c sig2BeforeUpdate = querySig(KEY_SIGDISABLED);
            System.Assert.areEqual(1, sig1BeforeUpdate.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sig1BeforeUpdate, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications! Expected: 0; Actual: ' + sig1BeforeUpdate.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sig1BeforeUpdate, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Expected: 0; Actual: ' + sig1BeforeUpdate.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sig1BeforeUpdate, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Expected: 0; Actual: ' + sig1BeforeUpdate.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sig1BeforeUpdate, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Expected: 0; Actual: ' + sig1BeforeUpdate.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sig1BeforeUpdate, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Expected: 0; Actual: ' + sig1BeforeUpdate.get(FIELD_BOOKED_PLACES));

            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sig2BeforeUpdate), sigApplicationFieldsNotEmptyErrorMsg(sig2BeforeUpdate));

            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;
            ipa.reduivy__Study_Intake_Group__c = sig2.Id;
            update ipa;

            reduivy__Study_Intake_Group__c sig1AfterUpdate = querySig(KEY_SIGSTANDARD);
            reduivy__Study_Intake_Group__c sig2AfterUpdate = querySig(KEY_SIGDISABLED);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sig1AfterUpdate), sigApplicationFieldsNotEmptyErrorMsg(sig1AfterUpdate));
            System.Assert.areEqual(1, sig2AfterUpdate.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sig2AfterUpdate.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sig2AfterUpdate, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Expected: 0; Actual: ' + sig2AfterUpdate.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sig2AfterUpdate, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Expected: 0; Actual: ' + sig2AfterUpdate.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sig2AfterUpdate, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Expected: 0; Actual: ' + sig2AfterUpdate.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sig2AfterUpdate, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Expected: 0; Actual: ' + sig2AfterUpdate.get(FIELD_BOOKED_PLACES));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    @IsTest
    static void testSigAsAdmin_UpdateIpa_OfferToAccepted_Full() {
        User ADMIN_USER = testFactory.getReduAdminUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(ADMIN_USER) {
            reduivy__Study_Intake_Group__c sigBeforeInsertIpa = querySig(KEY_SIGSTANDARD);
            List<reduivy__Individual_Program_Application__c> ipaList = new List<reduivy__Individual_Program_Application__c>();

            for(Integer i = 0; i < STUDY_INTAKE_CAPACITY; i++){
                reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_OFFER, sigBeforeInsertIpa.Id, con.Id);
                ipaList.add(ipa);
            }
            insert ipaList;

            reduivy__Study_Intake_Group__c sigBeforeUpdateIpa = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(STUDY_INTAKE_CAPACITY, sigBeforeUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before update!');
            System.Assert.areEqual(STUDY_INTAKE_CAPACITY, sigBeforeUpdateIpa.reduivy__Approved_Applications__c, 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places before update!');
            
            for(Integer i = 0; i < STUDY_INTAKE_CAPACITY - 1; i++) {
                ipaList[i].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;
            }

            update ipaList;

            reduivy__Study_Intake_Group__c sigAfterUpdate9Ipa = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(STUDY_INTAKE_CAPACITY, sigAfterUpdate9Ipa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(STUDY_INTAKE_CAPACITY, sigAfterUpdate9Ipa.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.areEqual(STUDY_INTAKE_CAPACITY - 1, sigAfterUpdate9Ipa.reduivy__Accepted_Applications__c, 'Wrong Accepted Applications!');
            System.Assert.areEqual(STUDY_INTAKE_CAPACITY - 1, sigAfterUpdate9Ipa.reduivy__Booked_Places__c, 'Wrong Booked Places!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdate9Ipa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdate9Ipa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications!');

            ipaList[STUDY_INTAKE_CAPACITY - 1].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;

            update ipaList[STUDY_INTAKE_CAPACITY - 1];
            
            reduivy__Study_Intake_Group__c sigAfterUpdate1Ipa = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(STUDY_INTAKE_CAPACITY, sigAfterUpdate1Ipa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(STUDY_INTAKE_CAPACITY, sigAfterUpdate1Ipa.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.areEqual(STUDY_INTAKE_CAPACITY, sigAfterUpdate1Ipa.reduivy__Accepted_Applications__c, 'Wrong Accepted Applications!');
            System.Assert.areEqual(STUDY_INTAKE_CAPACITY, sigAfterUpdate1Ipa.reduivy__Booked_Places__c, 'Wrong Booked Places!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdate1Ipa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdate1Ipa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications!');

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description Test inserting 10 IPA with random statuses, updating 5 IPA, and asserting Study Intake rollups.
     */
    @IsTest
    static void testSigAsAdmin_InsertAndUpdateMultipleIpaStatuses() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        System.runAs(ADMIN_USER) {
            Contact con = getCon();
            reduivy__Study_Intake_Group__c sig = querySig(KEY_SIGSTANDARD);
            
            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>{
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_DRAFT, sig.Id, con.Id),        // 0
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sig.Id, con.Id),    // 1
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REVIEWING, sig.Id, con.Id),     // 2
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sig.Id, con.Id),      // 3
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_OFFER, sig.Id, con.Id),         // 4
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REJECTED, sig.Id, con.Id),      // 5
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sig.Id, con.Id),     // 6
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REVIEWING, sig.Id, con.Id),     // 7
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_CANCELLED, sig.Id, con.Id),     // 8
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sig.Id, con.Id)       // 9
            };
            insert ipas;
            
            reduivy__Study_Intake_Group__c sigAfterInsert = querySig(KEY_SIGSTANDARD);
            
            System.Assert.areEqual(8, sigAfterInsert.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after insert');
            System.Assert.areEqual(3, sigAfterInsert.reduivy__Approved_Applications__c, 'Approved Applications wrong after insert');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterInsert, FIELD_ACCEPTED_APPLICATIONS), 'Accepted Applications should be empty, actual: ' + sigAfterInsert.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.areEqual(1, sigAfterInsert.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after insert');
            System.Assert.areEqual(2, sigAfterInsert.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after insert');
            System.Assert.areEqual(
                sigAfterInsert.reduivy__Accepted_Applications__c, 
                sigAfterInsert.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after insert'
            );
            
            // Now update 5 of the IPAs
            ipas[1].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING;       // Submitted -> Reviewing
            ipas[2].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;        // Reviewing -> Approved
            ipas[4].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;  // Offer -> Offer Accepted
            ipas[7].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;        // Reviewing -> Approved
            ipas[8].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_CANCELLED;       // Cancelled -> Cancelled (still no rollup)
            update ipas;
            
            reduivy__Study_Intake_Group__c sigAfterUpdate = querySig(KEY_SIGSTANDARD);
            
            System.Assert.areEqual(8, sigAfterUpdate.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after update');
            System.Assert.areEqual(5, sigAfterUpdate.reduivy__Approved_Applications__c, 'Approved Applications wrong after update');
            System.Assert.areEqual(1, sigAfterUpdate.reduivy__Accepted_Applications__c, 'Accepted Applications wrong after update');
            System.Assert.areEqual(1, sigAfterUpdate.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after update');
            System.Assert.areEqual(1, sigAfterUpdate.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after update');
            System.Assert.areEqual(
                sigAfterUpdate.reduivy__Accepted_Applications__c, 
                sigAfterUpdate.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after update'
            );
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description Test inserting 10 IPA with random statuses, updating 5 IPA, and asserting Study Intake rollups.
     */
    @IsTest
    static void testSigAsAdmin_InsertAndUpdateMultipleIpaStatuses_2() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        System.runAs(ADMIN_USER) {
            Contact con = getCon();
            reduivy__Study_Intake_Group__c sig = querySig(KEY_SIGSTANDARD);
            
            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>{
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sig.Id, con.Id),    // 0
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sig.Id, con.Id),    // 1
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REVIEWING, sig.Id, con.Id),     // 2
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sig.Id, con.Id),      // 3
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sig.Id, con.Id),      // 4
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REJECTED, sig.Id, con.Id),      // 5
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REJECTED, sig.Id, con.Id),      // 6
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REVIEWING, sig.Id, con.Id),     // 7
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_CANCELLED, sig.Id, con.Id),     // 8
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_DRAFT, sig.Id, con.Id)          // 9
            };
            insert ipas;
            
            reduivy__Study_Intake_Group__c sigAfterInsert = querySig(KEY_SIGSTANDARD);
            
            System.Assert.areEqual(8, sigAfterInsert.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after insert');
            System.Assert.areEqual(2, sigAfterInsert.reduivy__Approved_Applications__c, 'Approved Applications wrong after insert');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterInsert, FIELD_ACCEPTED_APPLICATIONS), 'Accepted Applications should be empty, actual: ' + sigAfterInsert.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.areEqual(2, sigAfterInsert.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after insert');
            System.Assert.areEqual(2, sigAfterInsert.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after insert');
            System.Assert.areEqual(
                sigAfterInsert.reduivy__Accepted_Applications__c, 
                sigAfterInsert.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after insert'
            );
            
            // Update
            ipas[0].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING;       // Submitted -> Reviewing
            ipas[2].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;        // Reviewing -> Approved
            ipas[4].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;  // Approved -> Offer Accepted
            ipas[6].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_CANCELLED;       // Rejected -> Cancelled
            ipas[9].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_CANCELLED;       // Draft -> Cancelled
            update ipas;
            
            reduivy__Study_Intake_Group__c sigAfterUpdate = querySig(KEY_SIGSTANDARD);
            
            System.Assert.areEqual(7, sigAfterUpdate.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after update');
            System.Assert.areEqual(3, sigAfterUpdate.reduivy__Approved_Applications__c, 'Approved Applications wrong after update');
            System.Assert.areEqual(1, sigAfterUpdate.reduivy__Accepted_Applications__c, 'Accepted Applications wrong after update');
            System.Assert.areEqual(1, sigAfterUpdate.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after update');
            System.Assert.areEqual(2, sigAfterUpdate.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after update');
            System.Assert.areEqual(
                sigAfterUpdate.reduivy__Accepted_Applications__c, 
                sigAfterUpdate.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after update'
            );
                 
            
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }


    /**
     * @description Test inserting 10 IPA with random statuses, updating 5 IPA, and asserting Study Intake rollups.
     */
    @IsTest
    static void testSigAsAdmin_InsertAndUpdateMultipleIpaStatuses_3() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        System.runAs(ADMIN_USER) {
            Contact con = getCon();
            reduivy__Study_Intake_Group__c sig = querySig(KEY_SIGSTANDARD);
            
            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>{
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_DRAFT, sig.Id, con.Id),           // 0
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sig.Id, con.Id),       // 1
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sig.Id, con.Id),       // 2
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REVIEWING, sig.Id, con.Id),        // 3
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sig.Id, con.Id),         // 4
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REJECTED, sig.Id, con.Id),         // 5
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REJECTED, sig.Id, con.Id),         // 6
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REVIEWING, sig.Id, con.Id),        // 7
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_CANCELLED, sig.Id, con.Id),        // 8
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sig.Id, con.Id)          // 9
            };
            insert ipas;
            
            reduivy__Study_Intake_Group__c sigAfterInsert = querySig(KEY_SIGSTANDARD);
            
            System.Assert.areEqual(8, sigAfterInsert.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after insert');
            System.Assert.areEqual(2, sigAfterInsert.reduivy__Approved_Applications__c, 'Approved Applications wrong after insert');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterInsert, FIELD_ACCEPTED_APPLICATIONS), 'Accepted Applications should be empty, actual: ' + sigAfterInsert.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.areEqual(2, sigAfterInsert.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after insert');
            System.Assert.areEqual(2, sigAfterInsert.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after insert');
            System.Assert.areEqual(
                sigAfterInsert.reduivy__Accepted_Applications__c, 
                sigAfterInsert.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after insert'
            );
            
            // Update
            ipas[1].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING;        // Submitted -> Reviewing
            ipas[2].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING;        // Submitted -> Reviewing
            ipas[4].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;   // Approved -> Offer Accepted
            ipas[5].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_CANCELLED;        // Rejected -> Cancelled
            ipas[7].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;         // Reviewing -> Approved
            update ipas;
            
            reduivy__Study_Intake_Group__c sigAfterUpdate = querySig(KEY_SIGSTANDARD);
            
            System.Assert.areEqual(7, sigAfterUpdate.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after update');
            System.Assert.areEqual(3, sigAfterUpdate.reduivy__Approved_Applications__c, 'Approved Applications wrong after update');
            System.Assert.areEqual(1, sigAfterUpdate.reduivy__Accepted_Applications__c, 'Accepted Applications wrong after update');
            System.Assert.areEqual(1, sigAfterUpdate.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after update');
            System.Assert.areEqual(3, sigAfterUpdate.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after update');
            System.Assert.areEqual(
                sigAfterUpdate.reduivy__Accepted_Applications__c, 
                sigAfterUpdate.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after update'
            );
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description Test inserting 10 IPA with random statuses, updating 5 IPA, and asserting Study Intake rollups.
     */
    @IsTest
    static void testSigAsAdmin_InsertAndUpdateMultipleIpaStatuses_4() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        System.runAs(ADMIN_USER) {
            Contact con = getCon();
            reduivy__Study_Intake_Group__c sig = querySig(KEY_SIGSTANDARD);
            
            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>{
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_DRAFT, sig.Id, con.Id),           // 0
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sig.Id, con.Id),       // 1
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sig.Id, con.Id),       // 2
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REVIEWING, sig.Id, con.Id),        // 3
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sig.Id, con.Id),         // 4
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REJECTED, sig.Id, con.Id),         // 5
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REJECTED, sig.Id, con.Id),         // 6
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REVIEWING, sig.Id, con.Id),        // 7
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_CANCELLED, sig.Id, con.Id),        // 8
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sig.Id, con.Id)          // 9
            };
            insert ipas;
            
            reduivy__Study_Intake_Group__c sigAfterInsert = querySig(KEY_SIGSTANDARD);
            
            System.Assert.areEqual(8, sigAfterInsert.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after insert');
            System.Assert.areEqual(2, sigAfterInsert.reduivy__Approved_Applications__c, 'Approved Applications wrong after insert');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterInsert, FIELD_ACCEPTED_APPLICATIONS), 'Accepted Applications should be empty, actual: ' + sigAfterInsert.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.areEqual(2, sigAfterInsert.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after insert');
            System.Assert.areEqual(2, sigAfterInsert.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after insert');
            System.Assert.areEqual(
                sigAfterInsert.reduivy__Accepted_Applications__c, 
                sigAfterInsert.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after insert'
            );
            
            // Update
            ipas[1].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING;        // Submitted -> Reviewing
            ipas[2].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REJECTED;         // Submitted -> Rejected
            ipas[4].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;   // Approved -> Offer Accepted
            ipas[5].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_CANCELLED;        // Rejected -> Cancelled
            ipas[7].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;         // Reviewing -> Approved
            update ipas;
            
            reduivy__Study_Intake_Group__c sigAfterUpdate = querySig(KEY_SIGSTANDARD);
            
            System.Assert.areEqual(7, sigAfterUpdate.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after update');
            System.Assert.areEqual(3, sigAfterUpdate.reduivy__Approved_Applications__c, 'Approved Applications wrong after update');
            System.Assert.areEqual(1, sigAfterUpdate.reduivy__Accepted_Applications__c, 'Accepted Applications wrong after update');
            System.Assert.areEqual(2, sigAfterUpdate.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after update');
            System.Assert.areEqual(2, sigAfterUpdate.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after update');
            System.Assert.areEqual(
                sigAfterUpdate.reduivy__Accepted_Applications__c, 
                sigAfterUpdate.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after update'
            );
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description Test inserting 10 IPA with random statuses, updating 5 IPA, and asserting Study Intake rollups. Over capacity is tested
     */
    @IsTest
    static void testSigAsAdmin_InsertAndUpdateMultipleIpaStatuses_OverCapacity() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        System.runAs(ADMIN_USER) {
            Contact con = getCon();
            reduivy__Study_Intake_Group__c sig = querySig(KEY_SIGSTANDARD);
            
            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>{
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_DRAFT, sig.Id, con.Id),           // 0
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sig.Id, con.Id),       // 1
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REVIEWING, sig.Id, con.Id),        // 2
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED, sig.Id, con.Id),   // 3
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sig.Id, con.Id),         // 4
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sig.Id, con.Id),         // 5
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REVIEWING, sig.Id, con.Id),        // 6
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sig.Id, con.Id),         // 7
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_CANCELLED, sig.Id, con.Id),        // 8
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REJECTED, sig.Id, con.Id)          // 9
            };
            insert ipas;
            
            reduivy__Study_Intake_Group__c sigAfterInsert = querySig(KEY_SIGSTANDARD);
            
            System.Assert.areEqual(8, sigAfterInsert.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after insert');
            System.Assert.areEqual(4, sigAfterInsert.reduivy__Approved_Applications__c, 'Approved Applications wrong after insert');
            System.Assert.areEqual(1, sigAfterInsert.reduivy__Accepted_Applications__c, 'Accepted Applications wrong after insert');
            System.Assert.areEqual(1, sigAfterInsert.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after insert');
            System.Assert.areEqual(2, sigAfterInsert.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after insert');
            System.Assert.areEqual(
                sigAfterInsert.reduivy__Accepted_Applications__c, 
                sigAfterInsert.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after insert'
            );
            
            // Update
            ipas[1].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;      // Submitted -> OFFER_ACCEPTED
            ipas[2].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;      // Reviewing -> OFFER_ACCEPTED
            ipas[4].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;      // Offer -> OFFER_ACCEPTED
            ipas[5].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;      // Rejected -> OFFER_ACCEPTED
            ipas[7].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;      // Approved -> OFFER_ACCEPTED


            try{
                update ipas;
                System.Assert.fail('Should be failed as the booked places is full! Booked Places: ' + sigAfterInsert.reduivy__Booked_Places__c);
            } catch(Exception exp) {
                String errorMsg = String.format(Label.Error_No_Available_Places_Remaining_In_Study_Intake_Group, new List<String> {
                    SIT_Helper.getObjectLabel(), sigAfterInsert.Name
                });

                System.Assert.isTrue(exp.getMessage().contains(errorMsg), 'Wrong error message! Expected: ' + errorMsg + ', Actual: ' + exp.getMessage());
                
            }
            
            reduivy__Study_Intake_Group__c sigAfterUpdate = querySig(KEY_SIGSTANDARD);
            
            System.Assert.areEqual(8, sigAfterUpdate.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after insert');
            System.Assert.areEqual(4, sigAfterUpdate.reduivy__Approved_Applications__c, 'Approved Applications wrong after insert');
            System.Assert.areEqual(1, sigAfterUpdate.reduivy__Accepted_Applications__c, 'Accepted Applications wrong after insert');
            System.Assert.areEqual(1, sigAfterUpdate.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after insert');
            System.Assert.areEqual(2, sigAfterUpdate.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after insert');
            System.Assert.areEqual(
                sigAfterUpdate.reduivy__Accepted_Applications__c, 
                sigAfterUpdate.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after insert'
            );
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description Test inserting 10 IPA with random statuses, updating 5 IPA, and asserting Study Intake rollups.
     */
    @IsTest
    static void testSigAsAdmin_InsertAndUpdateMultipleIpaStatuses_5() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        System.runAs(ADMIN_USER) {
            Contact con = getCon();
            reduivy__Study_Intake_Group__c sig = querySig(KEY_SIGSTANDARD);
            
            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>{
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_DRAFT, sig.Id, con.Id),           // 0
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sig.Id, con.Id),       // 1
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REVIEWING, sig.Id, con.Id),        // 2
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sig.Id, con.Id),         // 3
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_OFFER, sig.Id, con.Id),            // 4
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REJECTED, sig.Id, con.Id),         // 5
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REVIEWING, sig.Id, con.Id),        // 6
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sig.Id, con.Id),         // 7
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_CANCELLED, sig.Id, con.Id),        // 8
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REJECTED, sig.Id, con.Id)          // 9
            };
            insert ipas;
            
            reduivy__Study_Intake_Group__c sigAfterInsert = querySig(KEY_SIGSTANDARD);
            
            System.Assert.areEqual(8, sigAfterInsert.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after insert');
            System.Assert.areEqual(3, sigAfterInsert.reduivy__Approved_Applications__c, 'Approved Applications wrong after insert');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterInsert, FIELD_ACCEPTED_APPLICATIONS), 'Accepted Applications should be empty, actual: ' + sigAfterInsert.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.areEqual(2, sigAfterInsert.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after insert');
            System.Assert.areEqual(2, sigAfterInsert.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after insert');
            System.Assert.areEqual(
                sigAfterInsert.reduivy__Accepted_Applications__c, 
                sigAfterInsert.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after insert'
            );
            
            // Update
            ipas[1].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING;        // Submitted -> Reviewing
            ipas[2].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;         // Reviewing -> Approved
            ipas[4].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;   // Offer -> Offer Accepted
            ipas[5].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_CANCELLED;        // Rejected -> Cancelled
            ipas[7].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REJECTED;         // Approved -> Rejected
            update ipas;
            
            reduivy__Study_Intake_Group__c sigAfterUpdate = querySig(KEY_SIGSTANDARD);
            
            System.Assert.areEqual(7, sigAfterUpdate.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after update');
            System.Assert.areEqual(3, sigAfterUpdate.reduivy__Approved_Applications__c, 'Approved Applications wrong after update');
            System.Assert.areEqual(1, sigAfterUpdate.reduivy__Accepted_Applications__c, 'Accepted Applications wrong after update');
            System.Assert.areEqual(2, sigAfterUpdate.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after update');
            System.Assert.areEqual(2, sigAfterUpdate.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after update');
            System.Assert.areEqual(
                sigAfterUpdate.reduivy__Accepted_Applications__c, 
                sigAfterUpdate.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after update'
            );
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description test as faculty, create approved ipa
     */
    @IsTest
    static void testSigAsFaculty_CreateIpa_Approved() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(FACULTY_USER) {
            reduivy__Study_Intake_Group__c sigBefore = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBefore), sigApplicationFieldsNotEmptyErrorMsg(sigBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sigBefore.Id, con.Id);
            insert ipa;
            
            reduivy__Study_Intake_Group__c sigAfter = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigAfter.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sigAfter.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Excepted: 0; Actual: ' + sigAfter.get(FIELD_BOOKED_PLACES));

        }
        
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description test as faculty, create offer ipa
     */
    @IsTest
    static void testSigAsFaculty_CreateIpa_Offer() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(FACULTY_USER) {
            reduivy__Study_Intake_Group__c sigBefore = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBefore), sigApplicationFieldsNotEmptyErrorMsg(sigBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_OFFER, sigBefore.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigAfter = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigAfter.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sigAfter.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Excepted: 0; Actual: ' + sigAfter.get(FIELD_BOOKED_PLACES));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description test as faculty, create offer accepted ipa
     */
    @IsTest
    static void testSigAsFaculty_CreateIpa_OfferAccepted() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        setEnableSigSetting(true);

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(FACULTY_USER) {
            reduivy__Study_Intake_Group__c sigBefore = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBefore), sigApplicationFieldsNotEmptyErrorMsg(sigBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED, sigBefore.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigAfter = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigAfter.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sigAfter.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.areEqual(1, sigAfter.reduivy__Accepted_Applications__c, 'Wrong Accepted Applications!');
            System.Assert.areEqual(1, sigAfter.reduivy__Booked_Places__c, 'Wrong Booked Places!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_REVIEWING_APPLICATIONS));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description test as faculty, create offer declined ipa
     */
    @IsTest
    static void testSigAsFaculty_CreateIpa_OfferDeclined() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(FACULTY_USER) {
            reduivy__Study_Intake_Group__c sigBefore = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBefore), sigApplicationFieldsNotEmptyErrorMsg(sigBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_OFFER_DECLINED, sigBefore.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigAfter = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigAfter.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sigAfter.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Excepted: 0; Actual: ' + sigAfter.get(FIELD_BOOKED_PLACES));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description test as faculty, create rejected ipa
     */
    @IsTest
    static void testSigAsFaculty_CreateIpa_Rejected() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(FACULTY_USER) {
            reduivy__Study_Intake_Group__c sigBefore = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBefore), sigApplicationFieldsNotEmptyErrorMsg(sigBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REJECTED, sigBefore.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigAfter = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigAfter.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sigAfter.reduivy__Rejected_Applications__c, 'Wrong Rejected Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Excepted: 0; Actual: ' + sigAfter.get(FIELD_BOOKED_PLACES));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description test as faculty, create reviewing ipa
     */
    @IsTest
    static void testSigAsFaculty_CreateIpa_Reviewing() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(FACULTY_USER) {
            reduivy__Study_Intake_Group__c sigBefore = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBefore), sigApplicationFieldsNotEmptyErrorMsg(sigBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REVIEWING, sigBefore.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigAfter = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigAfter.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sigAfter.reduivy__Reviewing_Applications__c, 'Wrong Reviewing Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Excepted: 0; Actual: ' + sigAfter.get(FIELD_BOOKED_PLACES));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description test as faculty, create reviewing awaiting docs ipa
     */
    @IsTest
    static void testSigAsFaculty_CreateIpa_ReviewingAwaitingDocs() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(FACULTY_USER) {
            reduivy__Study_Intake_Group__c sigBefore = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBefore), sigApplicationFieldsNotEmptyErrorMsg(sigBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(APPLICATION_STATUS_REVIEWING_AWAITING_DOCS, sigBefore.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigAfter = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigAfter.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sigAfter.reduivy__Reviewing_Applications__c, 'Wrong Reviewing Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Excepted: 0; Actual: ' + sigAfter.get(FIELD_BOOKED_PLACES));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description test as faculty, create submitted ipa
     */
    @IsTest
    static void testSigAsFaculty_CreateIpa_Submitted() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(FACULTY_USER) {
            reduivy__Study_Intake_Group__c sigBefore = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBefore), sigApplicationFieldsNotEmptyErrorMsg(sigBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sigBefore.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigAfter = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigAfter.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Excepted: 0; Actual: ' + sigAfter.get(FIELD_BOOKED_PLACES));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description test as faculty, create draft ipa
     */
    @IsTest
    static void testSigAsFaculty_CreateIpa_Draft() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(FACULTY_USER) {
            reduivy__Study_Intake_Group__c sigBefore = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBefore), sigApplicationFieldsNotEmptyErrorMsg(sigBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_DRAFT, sigBefore.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigAfter = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigAfter), sigApplicationFieldsNotEmptyErrorMsg(sigAfter));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description test as faculty, create cancelled ipa
     */
    @IsTest
    static void testSigAsFaculty_CreateIpa_Cancelled() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(FACULTY_USER) {
            reduivy__Study_Intake_Group__c sigBefore = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBefore), sigApplicationFieldsNotEmptyErrorMsg(sigBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_CANCELLED, sigBefore.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigAfter = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigAfter), sigApplicationFieldsNotEmptyErrorMsg(sigAfter));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testSigAsFaculty to update ipa from draft to submitted
     */
    @IsTest
    static void testSigAsFaculty_UpdateIpa_DraftToSubmitted() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(FACULTY_USER) {
            reduivy__Study_Intake_Group__c sigBeforeInsertIpa = querySig(KEY_SIGSTANDARD);
            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_DRAFT, sigBeforeInsertIpa.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigBeforeUpdateIpa = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBeforeUpdateIpa), sigApplicationFieldsNotEmptyErrorMsg(sigBeforeUpdateIpa));

            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_SUBMITTED;
            update ipa;

            reduivy__Study_Intake_Group__c sigAfterUpdateIpa = querySig(KEY_SIGSTANDARD);

            System.Assert.areEqual(1, sigAfterUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications! Excepted: 0; Actual: ' + sigAfterUpdateIpa.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Excepted: 0; Actual: ' + sigAfterUpdateIpa.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Excepted: 0; Actual: ' + sigAfterUpdateIpa.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Excepted: 0; Actual: ' + sigAfterUpdateIpa.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Excepted: 0; Actual: ' + sigAfterUpdateIpa.get(FIELD_BOOKED_PLACES));
            
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    @IsTest
    static void testSigAsFaculty_UpdateIpa_SubmittedToReviewing() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(FACULTY_USER) {
            reduivy__Study_Intake_Group__c sigBeforeInsertIpa = querySig(KEY_SIGSTANDARD);
            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sigBeforeInsertIpa.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigBeforeUpdateIpa = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigBeforeUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places before update!');

            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING;
            update ipa;

            reduivy__Study_Intake_Group__c sigAfterUpdateIpa = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigAfterUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sigAfterUpdateIpa.reduivy__Reviewing_Applications__c, 'Wrong Reviewing Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places!');
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    @IsTest
    static void testSigAsFaculty_UpdateIpa_ReviewingToApproved() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
    
        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(FACULTY_USER) {
            reduivy__Study_Intake_Group__c sigBeforeInsertIpa = querySig(KEY_SIGSTANDARD);
            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REVIEWING, sigBeforeInsertIpa.Id, con.Id);
            insert ipa;
    
            reduivy__Study_Intake_Group__c sigBeforeUpdateIpa = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigBeforeUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before update!');
            System.Assert.areEqual(1, sigBeforeUpdateIpa.reduivy__Reviewing_Applications__c, 'Wrong Reviewing Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places before update!');
    
            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;
            update ipa;
    
            reduivy__Study_Intake_Group__c sigAfterUpdateIpa = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigAfterUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sigAfterUpdateIpa.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places!');
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }
    
    @IsTest
    static void testSigAsFaculty_UpdateIpa_ApprovedToOffer() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(FACULTY_USER) {
            reduivy__Study_Intake_Group__c sigBeforeInsertIpa = querySig(KEY_SIGSTANDARD);
            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sigBeforeInsertIpa.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigBeforeUpdateIpa = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigBeforeUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before update!');
            System.Assert.areEqual(1, sigBeforeUpdateIpa.reduivy__Approved_Applications__c, 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places before update!');

            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER;
            update ipa;

            reduivy__Study_Intake_Group__c sigAfterUpdateIpa = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigAfterUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sigAfterUpdateIpa.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places!');
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    @IsTest
    static void testSigAsFaculty_UpdateIpa_OfferToAccepted() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(FACULTY_USER) {
            reduivy__Study_Intake_Group__c sigBeforeInsertIpa = querySig(KEY_SIGSTANDARD);
            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_OFFER, sigBeforeInsertIpa.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigBeforeUpdateIpa = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigBeforeUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before update!');
            System.Assert.areEqual(1, sigBeforeUpdateIpa.reduivy__Approved_Applications__c, 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places before update!');

            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;
            update ipa;

            reduivy__Study_Intake_Group__c sigAfterUpdateIpa = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigAfterUpdateIpa.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.areEqual(1, sigAfterUpdateIpa.reduivy__Accepted_Applications__c, 'Wrong Accepted Applications!');
            System.Assert.areEqual(1, sigAfterUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sigAfterUpdateIpa.reduivy__Booked_Places__c, 'Wrong Booked Places!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications!');

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    @IsTest
    static void testSigAsFaculty_UpdateIpa_OfferToDeclined() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
    
        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(FACULTY_USER) {
            reduivy__Study_Intake_Group__c sigBeforeInsertIpa = querySig(KEY_SIGSTANDARD);
            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_OFFER, sigBeforeInsertIpa.Id, con.Id);
            insert ipa;
    
            reduivy__Study_Intake_Group__c sigBeforeUpdateIpa = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigBeforeUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before update!');
            System.Assert.areEqual(1, sigBeforeUpdateIpa.reduivy__Approved_Applications__c, 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places before update!');
    
            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_DECLINED;
            update ipa;
    
            reduivy__Study_Intake_Group__c sigAfterUpdateIpa = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigAfterUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sigBeforeUpdateIpa.reduivy__Approved_Applications__c, 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places!');
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }
    
    @IsTest
    static void testSigAsFaculty_UpdateIpa_ReviewingToRejected() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
    
        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(FACULTY_USER) {
            reduivy__Study_Intake_Group__c sigBeforeInsertIpa = querySig(KEY_SIGSTANDARD);
            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REVIEWING, sigBeforeInsertIpa.Id, con.Id);
            insert ipa;
    
            reduivy__Study_Intake_Group__c sigBeforeUpdateIpa = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigBeforeUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before update!');
            System.Assert.areEqual(1, sigBeforeUpdateIpa.reduivy__Reviewing_Applications__c, 'Wrong Reviewing Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places before update!');
    
            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REJECTED;
            update ipa;
    
            reduivy__Study_Intake_Group__c sigAfterUpdateIpa = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigAfterUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sigAfterUpdateIpa.reduivy__Rejected_Applications__c, 'Wrong Rejected Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places!');
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    @IsTest
    static void testSigAsFaculty_UpdateIpa_SubmittedToCancelled() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(FACULTY_USER) {
            reduivy__Study_Intake_Group__c sigBeforeInsertIpa = querySig(KEY_SIGSTANDARD);
            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sigBeforeInsertIpa.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigBeforeUpdateIpa = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigBeforeUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places before update!');

            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_CANCELLED;
            update ipa;

            reduivy__Study_Intake_Group__c sigAfterUpdateIpa = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigAfterUpdateIpa), sigApplicationFieldsNotEmptyErrorMsg(sigAfterUpdateIpa));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testSigAsFaculty to delete and undelete IPA with status Submitted
     */
    @IsTest
    static void testSigAsFaculty_DeleteUndeleteIpa_Submitted() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(FACULTY_USER) {
            reduivy__Study_Intake_Group__c sigBeforeInsert = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBeforeInsert), sigApplicationFieldsNotEmptyErrorMsg(sigBeforeInsert));

            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>();

            for (Integer i = 0; i < 5; i++) {
                ipas.add(newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sigBeforeInsert.Id, con.Id));
            }
            insert ipas;

            reduivy__Study_Intake_Group__c sigBeforeDelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(5, sigBeforeDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before delete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_BOOKED_PLACES));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_REVIEWING_APPLICATIONS));

            delete ipas[0];

            reduivy__Study_Intake_Group__c sigAfterDelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(4, sigAfterDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after delete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_BOOKED_PLACES));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_REVIEWING_APPLICATIONS));

            undelete ipas[0];

            reduivy__Study_Intake_Group__c sigAfterUndelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(5, sigAfterUndelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after undelete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_BOOKED_PLACES));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_REVIEWING_APPLICATIONS));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }


    /**
     * @description testSigAsFaculty to delete and undelete IPA with status Draft
     */
    @IsTest
    static void testSigAsFaculty_DeleteUndeleteIpa_Draft() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(FACULTY_USER) {
            reduivy__Study_Intake_Group__c sigBeforeInsert = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBeforeInsert), sigApplicationFieldsNotEmptyErrorMsg(sigBeforeInsert));
            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>();

            for (Integer i = 0; i < 5; i++) {
                ipas.add(newIpaWithSig(IPA_Helper.APPLICATION_STATUS_DRAFT, sigBeforeInsert.Id, con.Id));
            }
            insert ipas;

            reduivy__Study_Intake_Group__c sigBeforeDelete = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBeforeDelete), sigApplicationFieldsNotEmptyErrorMsg(sigBeforeDelete));

            delete ipas[0];
            reduivy__Study_Intake_Group__c sigAfterDelete = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigAfterDelete), sigApplicationFieldsNotEmptyErrorMsg(sigAfterDelete));

            undelete ipas[0];
            reduivy__Study_Intake_Group__c sigAfterUndelete = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigAfterUndelete), sigApplicationFieldsNotEmptyErrorMsg(sigAfterUndelete));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testSigAsFaculty to delete and undelete IPA with status Reviewing
     */
    @IsTest
    static void testSigAsFaculty_DeleteUndeleteIpa_Reviewing() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(FACULTY_USER) {
            reduivy__Study_Intake_Group__c sigBeforeInsert = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBeforeInsert), sigApplicationFieldsNotEmptyErrorMsg(sigBeforeInsert));

            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>();

            for (Integer i = 0; i < 5; i++) {
                ipas.add(newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REVIEWING, sigBeforeInsert.Id, con.Id));
            }
            insert ipas;

            reduivy__Study_Intake_Group__c sigBeforeDelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(5, sigBeforeDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before delete!');
            System.Assert.areEqual(5, sigBeforeDelete.reduivy__Reviewing_Applications__c, 'Wrong Reviewing Applications before delete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_BOOKED_PLACES));

            delete ipas[0];
            reduivy__Study_Intake_Group__c sigAfterDelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(4, sigAfterDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after delete!');
            System.Assert.areEqual(4, sigAfterDelete.reduivy__Reviewing_Applications__c, 'Wrong Reviewing Applications after delete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_BOOKED_PLACES));

            undelete ipas[0];
            reduivy__Study_Intake_Group__c sigAfterUndelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(5, sigAfterUndelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after undelete!');
            System.Assert.areEqual(5, sigAfterUndelete.reduivy__Reviewing_Applications__c, 'Wrong Reviewing Applications after undelete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_BOOKED_PLACES));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testSigAsFaculty to delete and undelete IPA with status Approved
     */
    @IsTest
    static void testSigAsFaculty_DeleteUndeleteIpa_Approved() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(FACULTY_USER) {
            reduivy__Study_Intake_Group__c sigBeforeInsert = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBeforeInsert), sigApplicationFieldsNotEmptyErrorMsg(sigBeforeInsert));

            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>();

            for (Integer i = 0; i < 5; i++) {
                ipas.add(newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sigBeforeInsert.Id, con.Id));
            }
            insert ipas;

            reduivy__Study_Intake_Group__c sigBeforeDelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(5, sigBeforeDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before delete!');
            System.Assert.areEqual(5, sigBeforeDelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications before delete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_BOOKED_PLACES));

            delete ipas[0];
            reduivy__Study_Intake_Group__c sigAfterDelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(4, sigAfterDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after delete!');
            System.Assert.areEqual(4, sigAfterDelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications after delete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_BOOKED_PLACES));

            undelete ipas[0];
            reduivy__Study_Intake_Group__c sigAfterUndelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(5, sigAfterUndelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after undelete!');
            System.Assert.areEqual(5, sigAfterUndelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications after undelete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_BOOKED_PLACES));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testSigAsFaculty to delete and undelete IPA with status Offer
     */
    @IsTest
    static void testSigAsFaculty_DeleteUndeleteIpa_Offer() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(FACULTY_USER) {
            reduivy__Study_Intake_Group__c sigBeforeInsert = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBeforeInsert), sigApplicationFieldsNotEmptyErrorMsg(sigBeforeInsert));

            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>();

            for (Integer i = 0; i < 5; i++) {
                ipas.add(newIpaWithSig(IPA_Helper.APPLICATION_STATUS_OFFER, sigBeforeInsert.Id, con.Id));
            }
            insert ipas;

            reduivy__Study_Intake_Group__c sigBeforeDelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(5, sigBeforeDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before delete!');
            System.Assert.areEqual(5, sigBeforeDelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications before delete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_BOOKED_PLACES));

            delete ipas[0];
            reduivy__Study_Intake_Group__c sigAfterDelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(4, sigAfterDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after delete!');
            System.Assert.areEqual(4, sigAfterDelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications after delete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_BOOKED_PLACES));

            undelete ipas[0];
            reduivy__Study_Intake_Group__c sigAfterUndelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(5, sigAfterUndelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after undelete!');
            System.Assert.areEqual(5, sigAfterUndelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications after undelete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_BOOKED_PLACES));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testSigAsFaculty to delete and undelete IPA with status Offer Accepted
     */
    @IsTest
    static void testSigAsFaculty_DeleteUndeleteIpa_OfferAccepted() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_CreateEnrollment_EXE'});


        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(FACULTY_USER) {
            reduivy__Study_Intake_Group__c sigBeforeInsert = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBeforeInsert), sigApplicationFieldsNotEmptyErrorMsg(sigBeforeInsert));


            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>();

            for (Integer i = 0; i < 5; i++) {
                ipas.add(newIpaWithSig(IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED, sigBeforeInsert.Id, con.Id));
            }
            insert ipas;

            reduivy__Study_Intake_Group__c sigBeforeDelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(5, sigBeforeDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before delete!');
            System.Assert.areEqual(5, sigBeforeDelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications before delete!');
            System.Assert.areEqual(5, sigBeforeDelete.reduivy__Accepted_Applications__c, 'Wrong Accepted Applications before delete!');
            System.Assert.areEqual(5, sigBeforeDelete.reduivy__Booked_Places__c, 'Wrong Booked Places before delete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_REVIEWING_APPLICATIONS));

            delete ipas[0];
            reduivy__Study_Intake_Group__c sigAfterDelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(4, sigAfterDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after delete!');
            System.Assert.areEqual(4, sigAfterDelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications after delete!');
            System.Assert.areEqual(4, sigAfterDelete.reduivy__Accepted_Applications__c, 'Wrong Accepted Applications after delete!');
            System.Assert.areEqual(4, sigAfterDelete.reduivy__Booked_Places__c, 'Wrong Booked Places after delete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_REVIEWING_APPLICATIONS));

            undelete ipas[0];
            reduivy__Study_Intake_Group__c sigAfterUndelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(5, sigAfterUndelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after undelete!');
            System.Assert.areEqual(5, sigAfterUndelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications after undelete!');
            System.Assert.areEqual(5, sigAfterUndelete.reduivy__Accepted_Applications__c, 'Wrong Accepted Applications after undelete!');
            System.Assert.areEqual(5, sigAfterUndelete.reduivy__Booked_Places__c, 'Wrong Booked Places after delete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_REVIEWING_APPLICATIONS));
        }

        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_CreateEnrollment_EXE'});
    }


    /**
     * @description testSigAsFaculty to delete and undelete IPA with status Offer Declined
     */
    @IsTest
    static void testSigAsFaculty_DeleteUndeleteIpa_OfferDeclined() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(FACULTY_USER) {
            reduivy__Study_Intake_Group__c sigBeforeInsert = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBeforeInsert), sigApplicationFieldsNotEmptyErrorMsg(sigBeforeInsert));

            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>();

            for (Integer i = 0; i < 5; i++) {
                ipas.add(newIpaWithSig(IPA_Helper.APPLICATION_STATUS_OFFER_DECLINED, sigBeforeInsert.Id, con.Id));
            }
            insert ipas;

            reduivy__Study_Intake_Group__c sigBeforeDelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(5, sigBeforeDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before delete!');
            System.Assert.areEqual(5, sigBeforeDelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications before delete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_BOOKED_PLACES));

            delete ipas[0];
            reduivy__Study_Intake_Group__c sigAfterDelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(4, sigAfterDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after delete!');
            System.Assert.areEqual(4, sigAfterDelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications after delete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_BOOKED_PLACES));

            undelete ipas[0];
            reduivy__Study_Intake_Group__c sigAfterUndelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(5, sigAfterUndelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after undelete!');
            System.Assert.areEqual(5, sigAfterUndelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications after undelete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_BOOKED_PLACES));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testSigAsFaculty to delete and undelete IPA with status Cancelled
     */
    @IsTest
    static void testSigAsFaculty_DeleteUndeleteIpa_Cancelled() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(FACULTY_USER) {
            reduivy__Study_Intake_Group__c sigBeforeInsert = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBeforeInsert), sigApplicationFieldsNotEmptyErrorMsg(sigBeforeInsert));

            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>();

            for (Integer i = 0; i < 5; i++) {
                ipas.add(newIpaWithSig(IPA_Helper.APPLICATION_STATUS_CANCELLED, sigBeforeInsert.Id, con.Id));
            }
            insert ipas;

            reduivy__Study_Intake_Group__c sigBeforeDelete = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBeforeDelete), sigApplicationFieldsNotEmptyErrorMsg(sigBeforeDelete));

            delete ipas[0];
            reduivy__Study_Intake_Group__c sigAfterDelete = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigAfterDelete), sigApplicationFieldsNotEmptyErrorMsg(sigAfterDelete));

            undelete ipas[0];
            reduivy__Study_Intake_Group__c sigAfterUndelete = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigAfterUndelete), sigApplicationFieldsNotEmptyErrorMsg(sigAfterUndelete));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testSigAsFaculty to rollup to a nonexist field
     */
    @IsTest
    static void testSigAsFaculty_RollupFieldNotFound() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        IPA_Helper.isNegativeTests = true;

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(FACULTY_USER) {
            reduivy__Study_Intake_Group__c sigBefore = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBefore), sigApplicationFieldsNotEmptyErrorMsg(sigBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_DRAFT, sigBefore.Id, con.Id);
            try{
                insert ipa;
                System.Assert.fail('Should be failed if reduivy__Rollup_Field_API_Name__c is not found!');
            } catch (Exception exp) {
                System.Assert.isTrue(
                    exp.getMessage().contains(getSigInvalidFieldErrorMessage()), 
                    'Wrong error message! Expected: ' + getSigInvalidFieldErrorMessage() + '; Actual: ' + exp.getMessage()
                );
            }

            reduivy__Study_Intake_Group__c sigAfter = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigAfter), sigApplicationFieldsNotEmptyErrorMsg(sigAfter));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testSigAsFaculty to rollup a nonexist ipa application status, no error should be thrown and will be simply ignored
     */
    @IsTest
    static void testSigAsFaculty_ApplicationStatusConfigNotFound() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        IPA_Helper.isNegativeTests = true;

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(FACULTY_USER) {
            reduivy__Study_Intake_Group__c sigBefore = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBefore), sigApplicationFieldsNotEmptyErrorMsg(sigBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_CANCELLED, sigBefore.Id, con.Id);
            insert ipa;


            reduivy__Study_Intake_Group__c sigAfter = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigAfter), sigApplicationFieldsNotEmptyErrorMsg(sigAfter));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testSigAsFaculty to rollup to a date field
     */
    @IsTest
    static void testSigAsFaculty_RollupFieldIsNotNumber() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        IPA_Helper.isNegativeTests = true;

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(FACULTY_USER) {
            reduivy__Study_Intake_Group__c sigBefore = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBefore), sigApplicationFieldsNotEmptyErrorMsg(sigBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sigBefore.Id, con.Id);
            try{
                insert ipa;
                System.Assert.fail('Should be failed if reduivy__Rollup_Field_API_Name__c is not number field!');
            } catch (Exception exp) {
                System.Assert.isTrue(
                    exp.getMessage().contains(getSigInvalidFieldErrorMessage()), 
                    'Wrong error message! Expected: ' + getSigInvalidFieldErrorMessage() + '; Actual: ' + exp.getMessage()
                );
            }

            reduivy__Study_Intake_Group__c sigAfter = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigAfter), sigApplicationFieldsNotEmptyErrorMsg(sigAfter));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testSigAsFaculty to rollup to a formula number field
     */
    @IsTest
    static void testSigAsFaculty_RollupFieldIsFormulaNumberField() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        IPA_Helper.isNegativeTests = true;

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(FACULTY_USER) {
            reduivy__Study_Intake_Group__c sigBefore = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBefore), sigApplicationFieldsNotEmptyErrorMsg(sigBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sigBefore.Id, con.Id);
            try{
                insert ipa;
                System.Assert.fail('Should be failed if reduivy__Rollup_Field_API_Name__c is formula field!');
            } catch (Exception exp) {
                System.Assert.isTrue(
                    exp.getMessage().contains(getSigInvalidFieldErrorMessage()), 
                    'Wrong error message! Expected: ' + getSigInvalidFieldErrorMessage() + '; Actual: ' + exp.getMessage()
                );
            }

            reduivy__Study_Intake_Group__c sigAfter = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigAfter), sigApplicationFieldsNotEmptyErrorMsg(sigAfter));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    @Istest
    static void testSigAsFaculty_CreateIpa_Approved_NoStudyIntakeGroup(){
        User FACULTY_USER = testFactory.getReduFacultyUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(FACULTY_USER) {
            reduivy__Study_Intake_Group__c sigBefore = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBefore), sigApplicationFieldsNotEmptyErrorMsg(sigBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, null, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigAfter = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigAfter), sigApplicationFieldsNotEmptyErrorMsg(sigAfter));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testSigAsFaculty to update ipa from submitted to approved, linking Study Intake during update
     */
    @IsTest
    static void testSigAsFaculty_UpdateIpa_SubmittedToApproved_NoStudyIntakeGroupToWithStudyIntakeGroup() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(FACULTY_USER) {
            reduivy__Study_Intake_Group__c sig = querySig(KEY_SIGSTANDARD);

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, null, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigBeforeUpdate = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBeforeUpdate), sigApplicationFieldsNotEmptyErrorMsg(sigBeforeUpdate));

            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;
            ipa.reduivy__Study_Intake_Group__c = sig.Id;
            update ipa;

            reduivy__Study_Intake_Group__c sigAfterUpdate = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigAfterUpdate.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sigAfterUpdate.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdate, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Expected: 0; Actual: ' + sigAfterUpdate.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdate, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Expected: 0; Actual: ' + sigAfterUpdate.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdate, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Expected: 0; Actual: ' + sigAfterUpdate.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdate, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Expected: 0; Actual: ' + sigAfterUpdate.get(FIELD_BOOKED_PLACES));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testSigAsFaculty to update ipa from submitted to approved, removing Study Intake during update
     */
    @IsTest
    static void testSigAsFaculty_UpdateIpa_SubmittedToApproved_WithStudyIntakeGroupToNoStudyIntakeGroup() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(FACULTY_USER) {
            reduivy__Study_Intake_Group__c sig = querySig(KEY_SIGSTANDARD);

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sig.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigBeforeUpdate = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigBeforeUpdate.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdate, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications! Expected: 0; Actual: ' + sigBeforeUpdate.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdate, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Expected: 0; Actual: ' + sigBeforeUpdate.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdate, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Expected: 0; Actual: ' + sigBeforeUpdate.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdate, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Expected: 0; Actual: ' + sigBeforeUpdate.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdate, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Expected: 0; Actual: ' + sigBeforeUpdate.get(FIELD_BOOKED_PLACES));

            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;
            ipa.reduivy__Study_Intake_Group__c = null;
            update ipa;

            reduivy__Study_Intake_Group__c sigAfterUpdate = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigAfterUpdate), sigApplicationFieldsNotEmptyErrorMsg(sigAfterUpdate));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testSigAsFaculty to update ipa from submitted to approved, and changing Study Intake during update
     */
    @IsTest
    static void testSigAsFaculty_UpdateIpa_SubmittedToApproved_StudyIntakeGroup1ToStudyIntakeGroup2() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(FACULTY_USER) {
            reduivy__Study_Intake_Group__c sig1 = querySig(KEY_SIGSTANDARD);
            reduivy__Study_Intake_Group__c sig2 = querySig(KEY_SIGDISABLED);

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sig1.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sig1BeforeUpdate = querySig(KEY_SIGSTANDARD);
            reduivy__Study_Intake_Group__c sig2BeforeUpdate = querySig(KEY_SIGDISABLED);
            System.Assert.areEqual(1, sig1BeforeUpdate.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sig1BeforeUpdate, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications! Expected: 0; Actual: ' + sig1BeforeUpdate.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sig1BeforeUpdate, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Expected: 0; Actual: ' + sig1BeforeUpdate.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sig1BeforeUpdate, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Expected: 0; Actual: ' + sig1BeforeUpdate.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sig1BeforeUpdate, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Expected: 0; Actual: ' + sig1BeforeUpdate.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sig1BeforeUpdate, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Expected: 0; Actual: ' + sig1BeforeUpdate.get(FIELD_BOOKED_PLACES));

            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sig2BeforeUpdate), sigApplicationFieldsNotEmptyErrorMsg(sig2BeforeUpdate));

            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;
            ipa.reduivy__Study_Intake_Group__c = sig2.Id;
            update ipa;

            reduivy__Study_Intake_Group__c sig1AfterUpdate = querySig(KEY_SIGSTANDARD);
            reduivy__Study_Intake_Group__c sig2AfterUpdate = querySig(KEY_SIGDISABLED);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sig1AfterUpdate), sigApplicationFieldsNotEmptyErrorMsg(sig1AfterUpdate));
            System.Assert.areEqual(1, sig2AfterUpdate.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sig2AfterUpdate.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sig2AfterUpdate, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Expected: 0; Actual: ' + sig2AfterUpdate.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sig2AfterUpdate, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Expected: 0; Actual: ' + sig2AfterUpdate.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sig2AfterUpdate, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Expected: 0; Actual: ' + sig2AfterUpdate.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sig2AfterUpdate, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Expected: 0; Actual: ' + sig2AfterUpdate.get(FIELD_BOOKED_PLACES));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    @IsTest
    static void testSigAsFaculty_UpdateIpa_OfferToAccepted_Full() {
        User FACULTY_USER = testFactory.getReduFacultyUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(FACULTY_USER) {
            reduivy__Study_Intake_Group__c sigBeforeInsertIpa = querySig(KEY_SIGSTANDARD);
            List<reduivy__Individual_Program_Application__c> ipaList = new List<reduivy__Individual_Program_Application__c>();

            for(Integer i = 0; i < STUDY_INTAKE_CAPACITY; i++){
                reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_OFFER, sigBeforeInsertIpa.Id, con.Id);
                ipaList.add(ipa);
            }
            insert ipaList;

            reduivy__Study_Intake_Group__c sigBeforeUpdateIpa = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(STUDY_INTAKE_CAPACITY, sigBeforeUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before update!');
            System.Assert.areEqual(STUDY_INTAKE_CAPACITY, sigBeforeUpdateIpa.reduivy__Approved_Applications__c, 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places before update!');
            
            for(Integer i = 0; i < STUDY_INTAKE_CAPACITY - 1; i++) {
                ipaList[i].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;
            }

            update ipaList;

            reduivy__Study_Intake_Group__c sigAfterUpdate9Ipa = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(STUDY_INTAKE_CAPACITY, sigAfterUpdate9Ipa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(STUDY_INTAKE_CAPACITY, sigAfterUpdate9Ipa.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.areEqual(STUDY_INTAKE_CAPACITY - 1, sigAfterUpdate9Ipa.reduivy__Accepted_Applications__c, 'Wrong Accepted Applications!');
            System.Assert.areEqual(STUDY_INTAKE_CAPACITY - 1, sigAfterUpdate9Ipa.reduivy__Booked_Places__c, 'Wrong Booked Places!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdate9Ipa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdate9Ipa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications!');

            ipaList[STUDY_INTAKE_CAPACITY - 1].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;

            update ipaList[STUDY_INTAKE_CAPACITY - 1];
            
            reduivy__Study_Intake_Group__c sigAfterUpdate1Ipa = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(STUDY_INTAKE_CAPACITY, sigAfterUpdate1Ipa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(STUDY_INTAKE_CAPACITY, sigAfterUpdate1Ipa.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.areEqual(STUDY_INTAKE_CAPACITY, sigAfterUpdate1Ipa.reduivy__Accepted_Applications__c, 'Wrong Accepted Applications!');
            System.Assert.areEqual(STUDY_INTAKE_CAPACITY, sigAfterUpdate1Ipa.reduivy__Booked_Places__c, 'Wrong Booked Places!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdate1Ipa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdate1Ipa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications!');

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description Test inserting 10 IPA with random statuses, updating 5 IPA, and asserting Study Intake rollups.
     */
    @IsTest
    static void testSigAsFaculty_InsertAndUpdateMultipleIpaStatuses() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        System.runAs(FACULTY_USER) {
            Contact con = getCon();
            reduivy__Study_Intake_Group__c sig = querySig(KEY_SIGSTANDARD);
            
            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>{
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_DRAFT, sig.Id, con.Id),        // 0
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sig.Id, con.Id),    // 1
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REVIEWING, sig.Id, con.Id),     // 2
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sig.Id, con.Id),      // 3
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_OFFER, sig.Id, con.Id),         // 4
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REJECTED, sig.Id, con.Id),      // 5
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sig.Id, con.Id),     // 6
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REVIEWING, sig.Id, con.Id),     // 7
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_CANCELLED, sig.Id, con.Id),     // 8
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sig.Id, con.Id)       // 9
            };
            insert ipas;
            
            reduivy__Study_Intake_Group__c sigAfterInsert = querySig(KEY_SIGSTANDARD);
            
            System.Assert.areEqual(8, sigAfterInsert.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after insert');
            System.Assert.areEqual(3, sigAfterInsert.reduivy__Approved_Applications__c, 'Approved Applications wrong after insert');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterInsert, FIELD_ACCEPTED_APPLICATIONS), 'Accepted Applications should be empty, actual: ' + sigAfterInsert.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.areEqual(1, sigAfterInsert.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after insert');
            System.Assert.areEqual(2, sigAfterInsert.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after insert');
            System.Assert.areEqual(
                sigAfterInsert.reduivy__Accepted_Applications__c, 
                sigAfterInsert.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after insert'
            );
            
            // Now update 5 of the IPAs
            ipas[1].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING;       // Submitted -> Reviewing
            ipas[2].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;        // Reviewing -> Approved
            ipas[4].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;  // Offer -> Offer Accepted
            ipas[7].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;        // Reviewing -> Approved
            ipas[8].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_CANCELLED;       // Cancelled -> Cancelled (still no rollup)
            update ipas;
            
            reduivy__Study_Intake_Group__c sigAfterUpdate = querySig(KEY_SIGSTANDARD);
            
            System.Assert.areEqual(8, sigAfterUpdate.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after update');
            System.Assert.areEqual(5, sigAfterUpdate.reduivy__Approved_Applications__c, 'Approved Applications wrong after update');
            System.Assert.areEqual(1, sigAfterUpdate.reduivy__Accepted_Applications__c, 'Accepted Applications wrong after update');
            System.Assert.areEqual(1, sigAfterUpdate.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after update');
            System.Assert.areEqual(1, sigAfterUpdate.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after update');
            System.Assert.areEqual(
                sigAfterUpdate.reduivy__Accepted_Applications__c, 
                sigAfterUpdate.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after update'
            );
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description Test inserting 10 IPA with random statuses, updating 5 IPA, and asserting Study Intake rollups.
     */
    @IsTest
    static void testSigAsFaculty_InsertAndUpdateMultipleIpaStatuses_2() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        System.runAs(FACULTY_USER) {
            Contact con = getCon();
            reduivy__Study_Intake_Group__c sig = querySig(KEY_SIGSTANDARD);
            
            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>{
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sig.Id, con.Id),    // 0
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sig.Id, con.Id),    // 1
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REVIEWING, sig.Id, con.Id),     // 2
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sig.Id, con.Id),      // 3
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sig.Id, con.Id),      // 4
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REJECTED, sig.Id, con.Id),      // 5
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REJECTED, sig.Id, con.Id),      // 6
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REVIEWING, sig.Id, con.Id),     // 7
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_CANCELLED, sig.Id, con.Id),     // 8
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_DRAFT, sig.Id, con.Id)          // 9
            };
            insert ipas;
            
            reduivy__Study_Intake_Group__c sigAfterInsert = querySig(KEY_SIGSTANDARD);
            
            System.Assert.areEqual(8, sigAfterInsert.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after insert');
            System.Assert.areEqual(2, sigAfterInsert.reduivy__Approved_Applications__c, 'Approved Applications wrong after insert');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterInsert, FIELD_ACCEPTED_APPLICATIONS), 'Accepted Applications should be empty, actual: ' + sigAfterInsert.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.areEqual(2, sigAfterInsert.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after insert');
            System.Assert.areEqual(2, sigAfterInsert.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after insert');
            System.Assert.areEqual(
                sigAfterInsert.reduivy__Accepted_Applications__c, 
                sigAfterInsert.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after insert'
            );
            
            // Update
            ipas[0].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING;       // Submitted -> Reviewing
            ipas[2].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;        // Reviewing -> Approved
            ipas[4].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;  // Approved -> Offer Accepted
            ipas[6].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_CANCELLED;       // Rejected -> Cancelled
            ipas[9].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_CANCELLED;       // Draft -> Cancelled
            update ipas;
            
            reduivy__Study_Intake_Group__c sigAfterUpdate = querySig(KEY_SIGSTANDARD);
            
            System.Assert.areEqual(7, sigAfterUpdate.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after update');
            System.Assert.areEqual(3, sigAfterUpdate.reduivy__Approved_Applications__c, 'Approved Applications wrong after update');
            System.Assert.areEqual(1, sigAfterUpdate.reduivy__Accepted_Applications__c, 'Accepted Applications wrong after update');
            System.Assert.areEqual(1, sigAfterUpdate.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after update');
            System.Assert.areEqual(2, sigAfterUpdate.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after update');
            System.Assert.areEqual(
                sigAfterUpdate.reduivy__Accepted_Applications__c, 
                sigAfterUpdate.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after update'
            );
                 
            
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }


    /**
     * @description Test inserting 10 IPA with random statuses, updating 5 IPA, and asserting Study Intake rollups.
     */
    @IsTest
    static void testSigAsFaculty_InsertAndUpdateMultipleIpaStatuses_3() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        System.runAs(FACULTY_USER) {
            Contact con = getCon();
            reduivy__Study_Intake_Group__c sig = querySig(KEY_SIGSTANDARD);
            
            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>{
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_DRAFT, sig.Id, con.Id),           // 0
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sig.Id, con.Id),       // 1
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sig.Id, con.Id),       // 2
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REVIEWING, sig.Id, con.Id),        // 3
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sig.Id, con.Id),         // 4
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REJECTED, sig.Id, con.Id),         // 5
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REJECTED, sig.Id, con.Id),         // 6
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REVIEWING, sig.Id, con.Id),        // 7
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_CANCELLED, sig.Id, con.Id),        // 8
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sig.Id, con.Id)          // 9
            };
            insert ipas;
            
            reduivy__Study_Intake_Group__c sigAfterInsert = querySig(KEY_SIGSTANDARD);
            
            System.Assert.areEqual(8, sigAfterInsert.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after insert');
            System.Assert.areEqual(2, sigAfterInsert.reduivy__Approved_Applications__c, 'Approved Applications wrong after insert');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterInsert, FIELD_ACCEPTED_APPLICATIONS), 'Accepted Applications should be empty, actual: ' + sigAfterInsert.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.areEqual(2, sigAfterInsert.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after insert');
            System.Assert.areEqual(2, sigAfterInsert.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after insert');
            System.Assert.areEqual(
                sigAfterInsert.reduivy__Accepted_Applications__c, 
                sigAfterInsert.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after insert'
            );
            
            // Update
            ipas[1].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING;        // Submitted -> Reviewing
            ipas[2].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING;        // Submitted -> Reviewing
            ipas[4].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;   // Approved -> Offer Accepted
            ipas[5].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_CANCELLED;        // Rejected -> Cancelled
            ipas[7].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;         // Reviewing -> Approved
            update ipas;
            
            reduivy__Study_Intake_Group__c sigAfterUpdate = querySig(KEY_SIGSTANDARD);
            
            System.Assert.areEqual(7, sigAfterUpdate.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after update');
            System.Assert.areEqual(3, sigAfterUpdate.reduivy__Approved_Applications__c, 'Approved Applications wrong after update');
            System.Assert.areEqual(1, sigAfterUpdate.reduivy__Accepted_Applications__c, 'Accepted Applications wrong after update');
            System.Assert.areEqual(1, sigAfterUpdate.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after update');
            System.Assert.areEqual(3, sigAfterUpdate.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after update');
            System.Assert.areEqual(
                sigAfterUpdate.reduivy__Accepted_Applications__c, 
                sigAfterUpdate.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after update'
            );
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description Test inserting 10 IPA with random statuses, updating 5 IPA, and asserting Study Intake rollups.
     */
    @IsTest
    static void testSigAsFaculty_InsertAndUpdateMultipleIpaStatuses_4() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        System.runAs(FACULTY_USER) {
            Contact con = getCon();
            reduivy__Study_Intake_Group__c sig = querySig(KEY_SIGSTANDARD);
            
            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>{
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_DRAFT, sig.Id, con.Id),           // 0
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sig.Id, con.Id),       // 1
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sig.Id, con.Id),       // 2
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REVIEWING, sig.Id, con.Id),        // 3
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sig.Id, con.Id),         // 4
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REJECTED, sig.Id, con.Id),         // 5
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REJECTED, sig.Id, con.Id),         // 6
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REVIEWING, sig.Id, con.Id),        // 7
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_CANCELLED, sig.Id, con.Id),        // 8
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sig.Id, con.Id)          // 9
            };
            insert ipas;
            
            reduivy__Study_Intake_Group__c sigAfterInsert = querySig(KEY_SIGSTANDARD);
            
            System.Assert.areEqual(8, sigAfterInsert.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after insert');
            System.Assert.areEqual(2, sigAfterInsert.reduivy__Approved_Applications__c, 'Approved Applications wrong after insert');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterInsert, FIELD_ACCEPTED_APPLICATIONS), 'Accepted Applications should be empty, actual: ' + sigAfterInsert.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.areEqual(2, sigAfterInsert.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after insert');
            System.Assert.areEqual(2, sigAfterInsert.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after insert');
            System.Assert.areEqual(
                sigAfterInsert.reduivy__Accepted_Applications__c, 
                sigAfterInsert.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after insert'
            );
            
            // Update
            ipas[1].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING;        // Submitted -> Reviewing
            ipas[2].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REJECTED;         // Submitted -> Rejected
            ipas[4].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;   // Approved -> Offer Accepted
            ipas[5].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_CANCELLED;        // Rejected -> Cancelled
            ipas[7].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;         // Reviewing -> Approved
            update ipas;
            
            reduivy__Study_Intake_Group__c sigAfterUpdate = querySig(KEY_SIGSTANDARD);
            
            System.Assert.areEqual(7, sigAfterUpdate.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after update');
            System.Assert.areEqual(3, sigAfterUpdate.reduivy__Approved_Applications__c, 'Approved Applications wrong after update');
            System.Assert.areEqual(1, sigAfterUpdate.reduivy__Accepted_Applications__c, 'Accepted Applications wrong after update');
            System.Assert.areEqual(2, sigAfterUpdate.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after update');
            System.Assert.areEqual(2, sigAfterUpdate.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after update');
            System.Assert.areEqual(
                sigAfterUpdate.reduivy__Accepted_Applications__c, 
                sigAfterUpdate.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after update'
            );
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description Test inserting 10 IPA with random statuses, updating 5 IPA, and asserting Study Intake rollups.
     */
    @IsTest
    static void testSigAsFaculty_InsertAndUpdateMultipleIpaStatuses_5() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        System.runAs(FACULTY_USER) {
            Contact con = getCon();
            reduivy__Study_Intake_Group__c sig = querySig(KEY_SIGSTANDARD);
            
            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>{
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_DRAFT, sig.Id, con.Id),           // 0
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sig.Id, con.Id),       // 1
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REVIEWING, sig.Id, con.Id),        // 2
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sig.Id, con.Id),         // 3
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_OFFER, sig.Id, con.Id),            // 4
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REJECTED, sig.Id, con.Id),         // 5
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REVIEWING, sig.Id, con.Id),        // 6
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sig.Id, con.Id),         // 7
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_CANCELLED, sig.Id, con.Id),        // 8
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REJECTED, sig.Id, con.Id)          // 9
            };
            insert ipas;
            
            reduivy__Study_Intake_Group__c sigAfterInsert = querySig(KEY_SIGSTANDARD);
            
            System.Assert.areEqual(8, sigAfterInsert.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after insert');
            System.Assert.areEqual(3, sigAfterInsert.reduivy__Approved_Applications__c, 'Approved Applications wrong after insert');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterInsert, FIELD_ACCEPTED_APPLICATIONS), 'Accepted Applications should be empty, actual: ' + sigAfterInsert.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.areEqual(2, sigAfterInsert.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after insert');
            System.Assert.areEqual(2, sigAfterInsert.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after insert');
            System.Assert.areEqual(
                sigAfterInsert.reduivy__Accepted_Applications__c, 
                sigAfterInsert.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after insert'
            );
            
            // Update
            ipas[1].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING;        // Submitted -> Reviewing
            ipas[2].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;         // Reviewing -> Approved
            ipas[4].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;   // Offer -> Offer Accepted
            ipas[5].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_CANCELLED;        // Rejected -> Cancelled
            ipas[7].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REJECTED;         // Approved -> Rejected
            update ipas;
            
            reduivy__Study_Intake_Group__c sigAfterUpdate = querySig(KEY_SIGSTANDARD);
            
            System.Assert.areEqual(7, sigAfterUpdate.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after update');
            System.Assert.areEqual(3, sigAfterUpdate.reduivy__Approved_Applications__c, 'Approved Applications wrong after update');
            System.Assert.areEqual(1, sigAfterUpdate.reduivy__Accepted_Applications__c, 'Accepted Applications wrong after update');
            System.Assert.areEqual(2, sigAfterUpdate.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after update');
            System.Assert.areEqual(2, sigAfterUpdate.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after update');
            System.Assert.areEqual(
                sigAfterUpdate.reduivy__Accepted_Applications__c, 
                sigAfterUpdate.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after update'
            );
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }


    /**
     * @description Test inserting 10 IPA with random statuses, updating 5 IPA, and asserting Study Intake rollups. Over capacity is tested
     */
    @IsTest
    static void testSigAsFaculty_InsertAndUpdateMultipleIpaStatuses_OverCapacity() {
        User FACULTY_USER = testFactory.getReduFacultyUser();
        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        System.runAs(FACULTY_USER) {
            Contact con = getCon();
            reduivy__Study_Intake_Group__c sig = querySig(KEY_SIGSTANDARD);
            
            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>{
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_DRAFT, sig.Id, con.Id),           // 0
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sig.Id, con.Id),       // 1
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REVIEWING, sig.Id, con.Id),        // 2
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED, sig.Id, con.Id),   // 3
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sig.Id, con.Id),         // 4
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sig.Id, con.Id),         // 5
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REVIEWING, sig.Id, con.Id),        // 6
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sig.Id, con.Id),         // 7
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_CANCELLED, sig.Id, con.Id),        // 8
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REJECTED, sig.Id, con.Id)          // 9
            };
            insert ipas;
            
            reduivy__Study_Intake_Group__c sigAfterInsert = querySig(KEY_SIGSTANDARD);
            
            System.Assert.areEqual(8, sigAfterInsert.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after insert');
            System.Assert.areEqual(4, sigAfterInsert.reduivy__Approved_Applications__c, 'Approved Applications wrong after insert');
            System.Assert.areEqual(1, sigAfterInsert.reduivy__Accepted_Applications__c, 'Accepted Applications wrong after insert');
            System.Assert.areEqual(1, sigAfterInsert.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after insert');
            System.Assert.areEqual(2, sigAfterInsert.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after insert');
            System.Assert.areEqual(
                sigAfterInsert.reduivy__Accepted_Applications__c, 
                sigAfterInsert.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after insert'
            );
            
            // Update
            ipas[1].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;      // Submitted -> OFFER_ACCEPTED
            ipas[2].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;      // Reviewing -> OFFER_ACCEPTED
            ipas[4].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;      // Offer -> OFFER_ACCEPTED
            ipas[5].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;      // Rejected -> OFFER_ACCEPTED
            ipas[7].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;      // Approved -> OFFER_ACCEPTED


            try{
                update ipas;
                System.Assert.fail('Should be failed as the booked places is full! Booked Places: ' + sigAfterInsert.reduivy__Booked_Places__c);
            } catch(Exception exp) {
                String errorMsg = String.format(Label.Error_No_Available_Places_Remaining_In_Study_Intake_Group, new List<String> {
                    SIT_Helper.getObjectLabel(), sigAfterInsert.Name
                });

                System.Assert.isTrue(exp.getMessage().contains(errorMsg), 'Wrong error message! Expected: ' + errorMsg + ', Actual: ' + exp.getMessage());
                
            }
            
            reduivy__Study_Intake_Group__c sigAfterUpdate = querySig(KEY_SIGSTANDARD);
            
            System.Assert.areEqual(8, sigAfterUpdate.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after insert');
            System.Assert.areEqual(4, sigAfterUpdate.reduivy__Approved_Applications__c, 'Approved Applications wrong after insert');
            System.Assert.areEqual(1, sigAfterUpdate.reduivy__Accepted_Applications__c, 'Accepted Applications wrong after insert');
            System.Assert.areEqual(1, sigAfterUpdate.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after insert');
            System.Assert.areEqual(2, sigAfterUpdate.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after insert');
            System.Assert.areEqual(
                sigAfterUpdate.reduivy__Accepted_Applications__c, 
                sigAfterUpdate.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after insert'
            );
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    
    /**
     * @description test as student, create approved ipa
     */
    @IsTest
    static void testSigAsStudent_CreateIpa_Approved() {
        
        User studentUser = testFactory.getStudentUser();
        
        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake_Group__c sigBefore = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBefore), sigApplicationFieldsNotEmptyErrorMsg(sigBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sigBefore.Id, con.Id);
            insert ipa;
            
            reduivy__Study_Intake_Group__c sigAfter = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigAfter.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sigAfter.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Excepted: 0; Actual: ' + sigAfter.get(FIELD_BOOKED_PLACES));

        }
        
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description test as student, create offer ipa
     */
    @IsTest
    static void testSigAsStudent_CreateIpa_Offer() {
        User studentUser = testFactory.getStudentUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake_Group__c sigBefore = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBefore), sigApplicationFieldsNotEmptyErrorMsg(sigBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_OFFER, sigBefore.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigAfter = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigAfter.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sigAfter.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Excepted: 0; Actual: ' + sigAfter.get(FIELD_BOOKED_PLACES));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description test as student, create offer accepted ipa
     */
    @IsTest
    static void testSigAsStudent_CreateIpa_OfferAccepted() {
        User studentUser = testFactory.getStudentUser();
        setEnableSigSetting(true);

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake_Group__c sigBefore = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBefore), sigApplicationFieldsNotEmptyErrorMsg(sigBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED, sigBefore.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigAfter = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigAfter.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sigAfter.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.areEqual(1, sigAfter.reduivy__Accepted_Applications__c, 'Wrong Accepted Applications!');
            System.Assert.areEqual(1, sigAfter.reduivy__Booked_Places__c, 'Wrong Booked Places!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_REVIEWING_APPLICATIONS));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description test as student, create offer declined ipa
     */
    @IsTest
    static void testSigAsStudent_CreateIpa_OfferDeclined() {
        User studentUser = testFactory.getStudentUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake_Group__c sigBefore = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBefore), sigApplicationFieldsNotEmptyErrorMsg(sigBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_OFFER_DECLINED, sigBefore.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigAfter = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigAfter.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sigAfter.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Excepted: 0; Actual: ' + sigAfter.get(FIELD_BOOKED_PLACES));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description test as student, create rejected ipa
     */
    @IsTest
    static void testSigAsStudent_CreateIpa_Rejected() {
        User studentUser = testFactory.getStudentUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake_Group__c sigBefore = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBefore), sigApplicationFieldsNotEmptyErrorMsg(sigBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REJECTED, sigBefore.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigAfter = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigAfter.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sigAfter.reduivy__Rejected_Applications__c, 'Wrong Rejected Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Excepted: 0; Actual: ' + sigAfter.get(FIELD_BOOKED_PLACES));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description test as student, create reviewing ipa
     */
    @IsTest
    static void testSigAsStudent_CreateIpa_Reviewing() {
        User studentUser = testFactory.getStudentUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake_Group__c sigBefore = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBefore), sigApplicationFieldsNotEmptyErrorMsg(sigBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REVIEWING, sigBefore.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigAfter = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigAfter.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sigAfter.reduivy__Reviewing_Applications__c, 'Wrong Reviewing Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Excepted: 0; Actual: ' + sigAfter.get(FIELD_BOOKED_PLACES));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description test as student, create reviewing awaiting docs ipa
     */
    @IsTest
    static void testSigAsStudent_CreateIpa_ReviewingAwaitingDocs() {
        User studentUser = testFactory.getStudentUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake_Group__c sigBefore = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBefore), sigApplicationFieldsNotEmptyErrorMsg(sigBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(APPLICATION_STATUS_REVIEWING_AWAITING_DOCS, sigBefore.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigAfter = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigAfter.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sigAfter.reduivy__Reviewing_Applications__c, 'Wrong Reviewing Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Excepted: 0; Actual: ' + sigAfter.get(FIELD_BOOKED_PLACES));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description test as student, create submitted ipa
     */
    @IsTest
    static void testSigAsStudent_CreateIpa_Submitted() {
        User studentUser = testFactory.getStudentUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake_Group__c sigBefore = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBefore), sigApplicationFieldsNotEmptyErrorMsg(sigBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sigBefore.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigAfter = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigAfter.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Excepted: 0; Actual: ' + sigAfter.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfter, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Excepted: 0; Actual: ' + sigAfter.get(FIELD_BOOKED_PLACES));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description test as student, create draft ipa
     */
    @IsTest
    static void testSigAsStudent_CreateIpa_Draft() {
        User studentUser = testFactory.getStudentUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake_Group__c sigBefore = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBefore), sigApplicationFieldsNotEmptyErrorMsg(sigBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_DRAFT, sigBefore.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigAfter = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigAfter), sigApplicationFieldsNotEmptyErrorMsg(sigAfter));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description test as student, create cancelled ipa
     */
    @IsTest
    static void testSigAsStudent_CreateIpa_Cancelled() {
        User studentUser = testFactory.getStudentUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake_Group__c sigBefore = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBefore), sigApplicationFieldsNotEmptyErrorMsg(sigBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_CANCELLED, sigBefore.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigAfter = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigAfter), sigApplicationFieldsNotEmptyErrorMsg(sigAfter));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testSigAsStudent to update ipa from draft to submitted
     */
    @IsTest
    static void testSigAsStudent_UpdateIpa_DraftToSubmitted() {
        User studentUser = testFactory.getStudentUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake_Group__c sigBeforeInsertIpa = querySig(KEY_SIGSTANDARD);
            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_DRAFT, sigBeforeInsertIpa.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigBeforeUpdateIpa = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBeforeUpdateIpa), sigApplicationFieldsNotEmptyErrorMsg(sigBeforeUpdateIpa));

            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_SUBMITTED;
            update ipa;

            reduivy__Study_Intake_Group__c sigAfterUpdateIpa = querySig(KEY_SIGSTANDARD);

            System.Assert.areEqual(1, sigAfterUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications! Excepted: 0; Actual: ' + sigAfterUpdateIpa.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Excepted: 0; Actual: ' + sigAfterUpdateIpa.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Excepted: 0; Actual: ' + sigAfterUpdateIpa.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Excepted: 0; Actual: ' + sigAfterUpdateIpa.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Excepted: 0; Actual: ' + sigAfterUpdateIpa.get(FIELD_BOOKED_PLACES));
            
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    @IsTest
    static void testSigAsStudent_UpdateIpa_SubmittedToReviewing() {
        User studentUser = testFactory.getStudentUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake_Group__c sigBeforeInsertIpa = querySig(KEY_SIGSTANDARD);
            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sigBeforeInsertIpa.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigBeforeUpdateIpa = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigBeforeUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places before update!');

            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING;
            update ipa;

            reduivy__Study_Intake_Group__c sigAfterUpdateIpa = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigAfterUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sigAfterUpdateIpa.reduivy__Reviewing_Applications__c, 'Wrong Reviewing Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places!');
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    @IsTest
    static void testSigAsStudent_UpdateIpa_ReviewingToApproved() {
        User studentUser = testFactory.getStudentUser();
    
        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake_Group__c sigBeforeInsertIpa = querySig(KEY_SIGSTANDARD);
            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REVIEWING, sigBeforeInsertIpa.Id, con.Id);
            insert ipa;
    
            reduivy__Study_Intake_Group__c sigBeforeUpdateIpa = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigBeforeUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before update!');
            System.Assert.areEqual(1, sigBeforeUpdateIpa.reduivy__Reviewing_Applications__c, 'Wrong Reviewing Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places before update!');
    
            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;
            update ipa;
    
            reduivy__Study_Intake_Group__c sigAfterUpdateIpa = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigAfterUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sigAfterUpdateIpa.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places!');
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }
    
    @IsTest
    static void testSigAsStudent_UpdateIpa_ApprovedToOffer() {
        User studentUser = testFactory.getStudentUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake_Group__c sigBeforeInsertIpa = querySig(KEY_SIGSTANDARD);
            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sigBeforeInsertIpa.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigBeforeUpdateIpa = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigBeforeUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before update!');
            System.Assert.areEqual(1, sigBeforeUpdateIpa.reduivy__Approved_Applications__c, 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places before update!');

            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER;
            update ipa;

            reduivy__Study_Intake_Group__c sigAfterUpdateIpa = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigAfterUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sigAfterUpdateIpa.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places!');
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    @IsTest
    static void testSigAsStudent_UpdateIpa_OfferToAccepted() {
        User studentUser = testFactory.getStudentUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake_Group__c sigBeforeInsertIpa = querySig(KEY_SIGSTANDARD);
            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_OFFER, sigBeforeInsertIpa.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigBeforeUpdateIpa = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigBeforeUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before update!');
            System.Assert.areEqual(1, sigBeforeUpdateIpa.reduivy__Approved_Applications__c, 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places before update!');

            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;
            update ipa;

            reduivy__Study_Intake_Group__c sigAfterUpdateIpa = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigAfterUpdateIpa.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.areEqual(1, sigAfterUpdateIpa.reduivy__Accepted_Applications__c, 'Wrong Accepted Applications!');
            System.Assert.areEqual(1, sigAfterUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sigAfterUpdateIpa.reduivy__Booked_Places__c, 'Wrong Booked Places!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications!');

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    @IsTest
    static void testSigAsStudent_UpdateIpa_OfferToDeclined() {
        User studentUser = testFactory.getStudentUser();
    
        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake_Group__c sigBeforeInsertIpa = querySig(KEY_SIGSTANDARD);
            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_OFFER, sigBeforeInsertIpa.Id, con.Id);
            insert ipa;
    
            reduivy__Study_Intake_Group__c sigBeforeUpdateIpa = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigBeforeUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before update!');
            System.Assert.areEqual(1, sigBeforeUpdateIpa.reduivy__Approved_Applications__c, 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places before update!');
    
            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_DECLINED;
            update ipa;
    
            reduivy__Study_Intake_Group__c sigAfterUpdateIpa = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigAfterUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sigBeforeUpdateIpa.reduivy__Approved_Applications__c, 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places!');
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }
    
    @IsTest
    static void testSigAsStudent_UpdateIpa_ReviewingToRejected() {
        User studentUser = testFactory.getStudentUser();
    
        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake_Group__c sigBeforeInsertIpa = querySig(KEY_SIGSTANDARD);
            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REVIEWING, sigBeforeInsertIpa.Id, con.Id);
            insert ipa;
    
            reduivy__Study_Intake_Group__c sigBeforeUpdateIpa = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigBeforeUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before update!');
            System.Assert.areEqual(1, sigBeforeUpdateIpa.reduivy__Reviewing_Applications__c, 'Wrong Reviewing Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places before update!');
    
            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REJECTED;
            update ipa;
    
            reduivy__Study_Intake_Group__c sigAfterUpdateIpa = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigAfterUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sigAfterUpdateIpa.reduivy__Rejected_Applications__c, 'Wrong Rejected Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places!');
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    @IsTest
    static void testSigAsStudent_UpdateIpa_SubmittedToCancelled() {
        User studentUser = testFactory.getStudentUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake_Group__c sigBeforeInsertIpa = querySig(KEY_SIGSTANDARD);
            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sigBeforeInsertIpa.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigBeforeUpdateIpa = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigBeforeUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places before update!');

            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_CANCELLED;
            update ipa;

            reduivy__Study_Intake_Group__c sigAfterUpdateIpa = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigAfterUpdateIpa), sigApplicationFieldsNotEmptyErrorMsg(sigAfterUpdateIpa));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testSigAsStudent to delete and undelete IPA with status Submitted
     */
    @IsTest
    static void testSigAsStudent_DeleteUndeleteIpa_Submitted() {
        User studentUser = testFactory.getStudentUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake_Group__c sigBeforeInsert = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBeforeInsert), sigApplicationFieldsNotEmptyErrorMsg(sigBeforeInsert));

            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>();

            for (Integer i = 0; i < 5; i++) {
                ipas.add(newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sigBeforeInsert.Id, con.Id));
            }
            insert ipas;

            reduivy__Study_Intake_Group__c sigBeforeDelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(5, sigBeforeDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before delete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_BOOKED_PLACES));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_REVIEWING_APPLICATIONS));

            delete ipas[0];

            reduivy__Study_Intake_Group__c sigAfterDelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(4, sigAfterDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after delete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_BOOKED_PLACES));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_REVIEWING_APPLICATIONS));

            undelete ipas[0];

            reduivy__Study_Intake_Group__c sigAfterUndelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(5, sigAfterUndelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after undelete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_BOOKED_PLACES));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_REVIEWING_APPLICATIONS));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }


    /**
     * @description testSigAsStudent to delete and undelete IPA with status Draft
     */
    @IsTest
    static void testSigAsStudent_DeleteUndeleteIpa_Draft() {
        User studentUser = testFactory.getStudentUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake_Group__c sigBeforeInsert = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBeforeInsert), sigApplicationFieldsNotEmptyErrorMsg(sigBeforeInsert));
            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>();

            for (Integer i = 0; i < 5; i++) {
                ipas.add(newIpaWithSig(IPA_Helper.APPLICATION_STATUS_DRAFT, sigBeforeInsert.Id, con.Id));
            }
            insert ipas;

            reduivy__Study_Intake_Group__c sigBeforeDelete = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBeforeDelete), sigApplicationFieldsNotEmptyErrorMsg(sigBeforeDelete));

            delete ipas[0];
            reduivy__Study_Intake_Group__c sigAfterDelete = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigAfterDelete), sigApplicationFieldsNotEmptyErrorMsg(sigAfterDelete));

            undelete ipas[0];
            reduivy__Study_Intake_Group__c sigAfterUndelete = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigAfterUndelete), sigApplicationFieldsNotEmptyErrorMsg(sigAfterUndelete));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testSigAsStudent to delete and undelete IPA with status Reviewing
     */
    @IsTest
    static void testSigAsStudent_DeleteUndeleteIpa_Reviewing() {
        User studentUser = testFactory.getStudentUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake_Group__c sigBeforeInsert = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBeforeInsert), sigApplicationFieldsNotEmptyErrorMsg(sigBeforeInsert));

            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>();

            for (Integer i = 0; i < 5; i++) {
                ipas.add(newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REVIEWING, sigBeforeInsert.Id, con.Id));
            }
            insert ipas;

            reduivy__Study_Intake_Group__c sigBeforeDelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(5, sigBeforeDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before delete!');
            System.Assert.areEqual(5, sigBeforeDelete.reduivy__Reviewing_Applications__c, 'Wrong Reviewing Applications before delete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_BOOKED_PLACES));

            delete ipas[0];
            reduivy__Study_Intake_Group__c sigAfterDelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(4, sigAfterDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after delete!');
            System.Assert.areEqual(4, sigAfterDelete.reduivy__Reviewing_Applications__c, 'Wrong Reviewing Applications after delete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_BOOKED_PLACES));

            undelete ipas[0];
            reduivy__Study_Intake_Group__c sigAfterUndelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(5, sigAfterUndelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after undelete!');
            System.Assert.areEqual(5, sigAfterUndelete.reduivy__Reviewing_Applications__c, 'Wrong Reviewing Applications after undelete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_BOOKED_PLACES));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testSigAsStudent to delete and undelete IPA with status Approved
     */
    @IsTest
    static void testSigAsStudent_DeleteUndeleteIpa_Approved() {
        User studentUser = testFactory.getStudentUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake_Group__c sigBeforeInsert = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBeforeInsert), sigApplicationFieldsNotEmptyErrorMsg(sigBeforeInsert));

            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>();

            for (Integer i = 0; i < 5; i++) {
                ipas.add(newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sigBeforeInsert.Id, con.Id));
            }
            insert ipas;

            reduivy__Study_Intake_Group__c sigBeforeDelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(5, sigBeforeDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before delete!');
            System.Assert.areEqual(5, sigBeforeDelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications before delete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_BOOKED_PLACES));

            delete ipas[0];
            reduivy__Study_Intake_Group__c sigAfterDelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(4, sigAfterDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after delete!');
            System.Assert.areEqual(4, sigAfterDelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications after delete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_BOOKED_PLACES));

            undelete ipas[0];
            reduivy__Study_Intake_Group__c sigAfterUndelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(5, sigAfterUndelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after undelete!');
            System.Assert.areEqual(5, sigAfterUndelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications after undelete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_BOOKED_PLACES));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testSigAsStudent to delete and undelete IPA with status Offer
     */
    @IsTest
    static void testSigAsStudent_DeleteUndeleteIpa_Offer() {
        User studentUser = testFactory.getStudentUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake_Group__c sigBeforeInsert = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBeforeInsert), sigApplicationFieldsNotEmptyErrorMsg(sigBeforeInsert));

            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>();

            for (Integer i = 0; i < 5; i++) {
                ipas.add(newIpaWithSig(IPA_Helper.APPLICATION_STATUS_OFFER, sigBeforeInsert.Id, con.Id));
            }
            insert ipas;

            reduivy__Study_Intake_Group__c sigBeforeDelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(5, sigBeforeDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before delete!');
            System.Assert.areEqual(5, sigBeforeDelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications before delete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_BOOKED_PLACES));

            delete ipas[0];
            reduivy__Study_Intake_Group__c sigAfterDelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(4, sigAfterDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after delete!');
            System.Assert.areEqual(4, sigAfterDelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications after delete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_BOOKED_PLACES));

            undelete ipas[0];
            reduivy__Study_Intake_Group__c sigAfterUndelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(5, sigAfterUndelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after undelete!');
            System.Assert.areEqual(5, sigAfterUndelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications after undelete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_BOOKED_PLACES));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testSigAsStudent to delete and undelete IPA with status Offer Accepted
     */
    @IsTest
    static void testSigAsStudent_DeleteUndeleteIpa_OfferAccepted() {
        User studentUser = testFactory.getStudentUser();
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_CreateEnrollment_EXE'});


        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake_Group__c sigBeforeInsert = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBeforeInsert), sigApplicationFieldsNotEmptyErrorMsg(sigBeforeInsert));


            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>();

            for (Integer i = 0; i < 5; i++) {
                ipas.add(newIpaWithSig(IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED, sigBeforeInsert.Id, con.Id));
            }
            insert ipas;

            reduivy__Study_Intake_Group__c sigBeforeDelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(5, sigBeforeDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before delete!');
            System.Assert.areEqual(5, sigBeforeDelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications before delete!');
            System.Assert.areEqual(5, sigBeforeDelete.reduivy__Accepted_Applications__c, 'Wrong Accepted Applications before delete!');
            System.Assert.areEqual(5, sigBeforeDelete.reduivy__Booked_Places__c, 'Wrong Booked Places before delete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_REVIEWING_APPLICATIONS));

            delete ipas[0];
            reduivy__Study_Intake_Group__c sigAfterDelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(4, sigAfterDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after delete!');
            System.Assert.areEqual(4, sigAfterDelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications after delete!');
            System.Assert.areEqual(4, sigAfterDelete.reduivy__Accepted_Applications__c, 'Wrong Accepted Applications after delete!');
            System.Assert.areEqual(4, sigAfterDelete.reduivy__Booked_Places__c, 'Wrong Booked Places after delete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_REVIEWING_APPLICATIONS));

            undelete ipas[0];
            reduivy__Study_Intake_Group__c sigAfterUndelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(5, sigAfterUndelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after undelete!');
            System.Assert.areEqual(5, sigAfterUndelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications after undelete!');
            System.Assert.areEqual(5, sigAfterUndelete.reduivy__Accepted_Applications__c, 'Wrong Accepted Applications after undelete!');
            System.Assert.areEqual(5, sigAfterUndelete.reduivy__Booked_Places__c, 'Wrong Booked Places after delete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_REVIEWING_APPLICATIONS));
        }

        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_CreateEnrollment_EXE'});
    }


    /**
     * @description testSigAsStudent to delete and undelete IPA with status Offer Declined
     */
    @IsTest
    static void testSigAsStudent_DeleteUndeleteIpa_OfferDeclined() {
        User studentUser = testFactory.getStudentUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake_Group__c sigBeforeInsert = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBeforeInsert), sigApplicationFieldsNotEmptyErrorMsg(sigBeforeInsert));

            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>();

            for (Integer i = 0; i < 5; i++) {
                ipas.add(newIpaWithSig(IPA_Helper.APPLICATION_STATUS_OFFER_DECLINED, sigBeforeInsert.Id, con.Id));
            }
            insert ipas;

            reduivy__Study_Intake_Group__c sigBeforeDelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(5, sigBeforeDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before delete!');
            System.Assert.areEqual(5, sigBeforeDelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications before delete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places before delete! Expected: 0; Actual: ' + sigBeforeDelete.get(FIELD_BOOKED_PLACES));

            delete ipas[0];
            reduivy__Study_Intake_Group__c sigAfterDelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(4, sigAfterDelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after delete!');
            System.Assert.areEqual(4, sigAfterDelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications after delete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterDelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after delete! Expected: 0; Actual: ' + sigAfterDelete.get(FIELD_BOOKED_PLACES));

            undelete ipas[0];
            reduivy__Study_Intake_Group__c sigAfterUndelete = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(5, sigAfterUndelete.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications after undelete!');
            System.Assert.areEqual(5, sigAfterUndelete.reduivy__Approved_Applications__c, 'Wrong Approved Applications after undelete!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUndelete, FIELD_BOOKED_PLACES), 'Wrong Booked Places after undelete! Expected: 0; Actual: ' + sigAfterUndelete.get(FIELD_BOOKED_PLACES));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testSigAsStudent to delete and undelete IPA with status Cancelled
     */
    @IsTest
    static void testSigAsStudent_DeleteUndeleteIpa_Cancelled() {
        User studentUser = testFactory.getStudentUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake_Group__c sigBeforeInsert = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBeforeInsert), sigApplicationFieldsNotEmptyErrorMsg(sigBeforeInsert));

            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>();

            for (Integer i = 0; i < 5; i++) {
                ipas.add(newIpaWithSig(IPA_Helper.APPLICATION_STATUS_CANCELLED, sigBeforeInsert.Id, con.Id));
            }
            insert ipas;

            reduivy__Study_Intake_Group__c sigBeforeDelete = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBeforeDelete), sigApplicationFieldsNotEmptyErrorMsg(sigBeforeDelete));

            delete ipas[0];
            reduivy__Study_Intake_Group__c sigAfterDelete = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigAfterDelete), sigApplicationFieldsNotEmptyErrorMsg(sigAfterDelete));

            undelete ipas[0];
            reduivy__Study_Intake_Group__c sigAfterUndelete = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigAfterUndelete), sigApplicationFieldsNotEmptyErrorMsg(sigAfterUndelete));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testSigAsStudent to rollup to a nonexist field
     */
    @IsTest
    static void testSigAsStudent_RollupFieldNotFound() {
        User studentUser = testFactory.getStudentUser();

        IPA_Helper.isNegativeTests = true;

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake_Group__c sigBefore = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBefore), sigApplicationFieldsNotEmptyErrorMsg(sigBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_DRAFT, sigBefore.Id, con.Id);
            try{
                insert ipa;
                System.Assert.fail('Should be failed if reduivy__Rollup_Field_API_Name__c is not found!');
            } catch (Exception exp) {
                System.Assert.isTrue(
                    exp.getMessage().contains(getSigInvalidFieldErrorMessage()), 
                    'Wrong error message! Expected: ' + getSigInvalidFieldErrorMessage() + '; Actual: ' + exp.getMessage()
                );
            }

            reduivy__Study_Intake_Group__c sigAfter = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigAfter), sigApplicationFieldsNotEmptyErrorMsg(sigAfter));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testSigAsStudent to rollup a nonexist ipa application status, no error should be thrown and will be simply ignored
     */
    @IsTest
    static void testSigAsStudent_ApplicationStatusConfigNotFound() {
        User studentUser = testFactory.getStudentUser();

        IPA_Helper.isNegativeTests = true;

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake_Group__c sigBefore = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBefore), sigApplicationFieldsNotEmptyErrorMsg(sigBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_CANCELLED, sigBefore.Id, con.Id);
            insert ipa;


            reduivy__Study_Intake_Group__c sigAfter = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigAfter), sigApplicationFieldsNotEmptyErrorMsg(sigAfter));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testSigAsStudent to rollup to a date field
     */
    @IsTest
    static void testSigAsStudent_RollupFieldIsNotNumber() {
        User studentUser = testFactory.getStudentUser();

        IPA_Helper.isNegativeTests = true;

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake_Group__c sigBefore = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBefore), sigApplicationFieldsNotEmptyErrorMsg(sigBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sigBefore.Id, con.Id);
            try{
                insert ipa;
                System.Assert.fail('Should be failed if reduivy__Rollup_Field_API_Name__c is not number field!');
            } catch (Exception exp) {
                System.Assert.isTrue(
                    exp.getMessage().contains(getSigInvalidFieldErrorMessage()), 
                    'Wrong error message! Expected: ' + getSigInvalidFieldErrorMessage() + '; Actual: ' + exp.getMessage()
                );
            }

            reduivy__Study_Intake_Group__c sigAfter = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigAfter), sigApplicationFieldsNotEmptyErrorMsg(sigAfter));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testSigAsStudent to rollup to a formula number field
     */
    @IsTest
    static void testSigAsStudent_RollupFieldIsFormulaNumberField() {
        User studentUser = testFactory.getStudentUser();

        IPA_Helper.isNegativeTests = true;

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake_Group__c sigBefore = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBefore), sigApplicationFieldsNotEmptyErrorMsg(sigBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sigBefore.Id, con.Id);
            try{
                insert ipa;
                System.Assert.fail('Should be failed if reduivy__Rollup_Field_API_Name__c is formula field!');
            } catch (Exception exp) {
                System.Assert.isTrue(
                    exp.getMessage().contains(getSigInvalidFieldErrorMessage()), 
                    'Wrong error message! Expected: ' + getSigInvalidFieldErrorMessage() + '; Actual: ' + exp.getMessage()
                );
            }

            reduivy__Study_Intake_Group__c sigAfter = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigAfter), sigApplicationFieldsNotEmptyErrorMsg(sigAfter));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    @Istest
    static void testSigAsStudent_CreateIpa_Approved_NoStudyIntakeGroup(){
        User studentUser = testFactory.getStudentUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake_Group__c sigBefore = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBefore), sigApplicationFieldsNotEmptyErrorMsg(sigBefore));

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, null, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigAfter = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigAfter), sigApplicationFieldsNotEmptyErrorMsg(sigAfter));

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testSigAsStudent to update ipa from submitted to approved, linking Study Intake during update
     */
    @IsTest
    static void testSigAsStudent_UpdateIpa_SubmittedToApproved_NoStudyIntakeGroupToWithStudyIntakeGroup() {
        User studentUser = testFactory.getStudentUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake_Group__c sig = querySig(KEY_SIGSTANDARD);

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, null, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigBeforeUpdate = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigBeforeUpdate), sigApplicationFieldsNotEmptyErrorMsg(sigBeforeUpdate));

            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;
            ipa.reduivy__Study_Intake_Group__c = sig.Id;
            update ipa;

            reduivy__Study_Intake_Group__c sigAfterUpdate = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigAfterUpdate.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sigAfterUpdate.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdate, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Expected: 0; Actual: ' + sigAfterUpdate.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdate, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Expected: 0; Actual: ' + sigAfterUpdate.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdate, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Expected: 0; Actual: ' + sigAfterUpdate.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdate, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Expected: 0; Actual: ' + sigAfterUpdate.get(FIELD_BOOKED_PLACES));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testSigAsStudent to update ipa from submitted to approved, removing Study Intake during update
     */
    @IsTest
    static void testSigAsStudent_UpdateIpa_SubmittedToApproved_WithStudyIntakeGroupToNoStudyIntakeGroup() {
        User studentUser = testFactory.getStudentUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake_Group__c sig = querySig(KEY_SIGSTANDARD);

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sig.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sigBeforeUpdate = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(1, sigBeforeUpdate.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdate, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications! Expected: 0; Actual: ' + sigBeforeUpdate.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdate, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Expected: 0; Actual: ' + sigBeforeUpdate.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdate, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Expected: 0; Actual: ' + sigBeforeUpdate.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdate, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Expected: 0; Actual: ' + sigBeforeUpdate.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdate, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Expected: 0; Actual: ' + sigBeforeUpdate.get(FIELD_BOOKED_PLACES));

            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;
            ipa.reduivy__Study_Intake_Group__c = null;
            update ipa;

            reduivy__Study_Intake_Group__c sigAfterUpdate = querySig(KEY_SIGSTANDARD);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sigAfterUpdate), sigApplicationFieldsNotEmptyErrorMsg(sigAfterUpdate));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description testSigAsStudent to update ipa from submitted to approved, and changing Study Intake during update
     */
    @IsTest
    static void testSigAsStudent_UpdateIpa_SubmittedToApproved_StudyIntakeGroup1ToStudyIntakeGroup2() {
        User studentUser = testFactory.getStudentUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake_Group__c sig1 = querySig(KEY_SIGSTANDARD);
            reduivy__Study_Intake_Group__c sig2 = querySig(KEY_SIGDISABLED);

            reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sig1.Id, con.Id);
            insert ipa;

            reduivy__Study_Intake_Group__c sig1BeforeUpdate = querySig(KEY_SIGSTANDARD);
            reduivy__Study_Intake_Group__c sig2BeforeUpdate = querySig(KEY_SIGDISABLED);
            System.Assert.areEqual(1, sig1BeforeUpdate.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sig1BeforeUpdate, FIELD_APPROVED_APPLICATIONS), 'Wrong Approved Applications! Expected: 0; Actual: ' + sig1BeforeUpdate.get(FIELD_APPROVED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sig1BeforeUpdate, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Expected: 0; Actual: ' + sig1BeforeUpdate.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sig1BeforeUpdate, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Expected: 0; Actual: ' + sig1BeforeUpdate.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sig1BeforeUpdate, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Expected: 0; Actual: ' + sig1BeforeUpdate.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sig1BeforeUpdate, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Expected: 0; Actual: ' + sig1BeforeUpdate.get(FIELD_BOOKED_PLACES));

            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sig2BeforeUpdate), sigApplicationFieldsNotEmptyErrorMsg(sig2BeforeUpdate));

            ipa.reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;
            ipa.reduivy__Study_Intake_Group__c = sig2.Id;
            update ipa;

            reduivy__Study_Intake_Group__c sig1AfterUpdate = querySig(KEY_SIGSTANDARD);
            reduivy__Study_Intake_Group__c sig2AfterUpdate = querySig(KEY_SIGDISABLED);
            System.Assert.isTrue(sigApplicationFieldsAreEmpty(sig1AfterUpdate), sigApplicationFieldsNotEmptyErrorMsg(sig1AfterUpdate));
            System.Assert.areEqual(1, sig2AfterUpdate.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(1, sig2AfterUpdate.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sig2AfterUpdate, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications! Expected: 0; Actual: ' + sig2AfterUpdate.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sig2AfterUpdate, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications! Expected: 0; Actual: ' + sig2AfterUpdate.get(FIELD_REJECTED_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sig2AfterUpdate, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications! Expected: 0; Actual: ' + sig2AfterUpdate.get(FIELD_REVIEWING_APPLICATIONS));
            System.Assert.isTrue(sigFieldIsEmpty(sig2AfterUpdate, FIELD_BOOKED_PLACES), 'Wrong Booked Places! Expected: 0; Actual: ' + sig2AfterUpdate.get(FIELD_BOOKED_PLACES));
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    @IsTest
    static void testSigAsStudent_UpdateIpa_OfferToAccepted_Full() {
        User studentUser = testFactory.getStudentUser();

        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Contact con = getCon();
        System.runAs(studentUser) {
            reduivy__Study_Intake_Group__c sigBeforeInsertIpa = querySig(KEY_SIGSTANDARD);
            List<reduivy__Individual_Program_Application__c> ipaList = new List<reduivy__Individual_Program_Application__c>();

            for(Integer i = 0; i < STUDY_INTAKE_CAPACITY; i++){
                reduivy__Individual_Program_Application__c ipa = newIpaWithSig(IPA_Helper.APPLICATION_STATUS_OFFER, sigBeforeInsertIpa.Id, con.Id);
                ipaList.add(ipa);
            }
            insert ipaList;

            reduivy__Study_Intake_Group__c sigBeforeUpdateIpa = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(STUDY_INTAKE_CAPACITY, sigBeforeUpdateIpa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications before update!');
            System.Assert.areEqual(STUDY_INTAKE_CAPACITY, sigBeforeUpdateIpa.reduivy__Approved_Applications__c, 'Wrong Approved Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_ACCEPTED_APPLICATIONS), 'Wrong Accepted Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications before update!');
            System.Assert.isTrue(sigFieldIsEmpty(sigBeforeUpdateIpa, FIELD_BOOKED_PLACES), 'Wrong Booked Places before update!');
            
            for(Integer i = 0; i < STUDY_INTAKE_CAPACITY - 1; i++) {
                ipaList[i].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;
            }

            update ipaList;

            reduivy__Study_Intake_Group__c sigAfterUpdate9Ipa = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(STUDY_INTAKE_CAPACITY, sigAfterUpdate9Ipa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(STUDY_INTAKE_CAPACITY, sigAfterUpdate9Ipa.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.areEqual(STUDY_INTAKE_CAPACITY - 1, sigAfterUpdate9Ipa.reduivy__Accepted_Applications__c, 'Wrong Accepted Applications!');
            System.Assert.areEqual(STUDY_INTAKE_CAPACITY - 1, sigAfterUpdate9Ipa.reduivy__Booked_Places__c, 'Wrong Booked Places!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdate9Ipa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdate9Ipa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications!');

            ipaList[STUDY_INTAKE_CAPACITY - 1].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;

            update ipaList[STUDY_INTAKE_CAPACITY - 1];
            
            reduivy__Study_Intake_Group__c sigAfterUpdate1Ipa = querySig(KEY_SIGSTANDARD);
            System.Assert.areEqual(STUDY_INTAKE_CAPACITY, sigAfterUpdate1Ipa.reduivy__Submitted_Applications__c, 'Wrong Submitted Applications!');
            System.Assert.areEqual(STUDY_INTAKE_CAPACITY, sigAfterUpdate1Ipa.reduivy__Approved_Applications__c, 'Wrong Approved Applications!');
            System.Assert.areEqual(STUDY_INTAKE_CAPACITY, sigAfterUpdate1Ipa.reduivy__Accepted_Applications__c, 'Wrong Accepted Applications!');
            System.Assert.areEqual(STUDY_INTAKE_CAPACITY, sigAfterUpdate1Ipa.reduivy__Booked_Places__c, 'Wrong Booked Places!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdate1Ipa, FIELD_REVIEWING_APPLICATIONS), 'Wrong Reviewing Applications!');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterUpdate1Ipa, FIELD_REJECTED_APPLICATIONS), 'Wrong Rejected Applications!');

        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description Test inserting 10 IPA with random statuses, updating 5 IPA, and asserting Study Intake rollups.
     */
    @IsTest
    static void testSigAsStudent_InsertAndUpdateMultipleIpaStatuses() {
        User studentUser = testFactory.getStudentUser();
        
        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        System.runAs(studentUser) {
            Contact con = getCon();
            reduivy__Study_Intake_Group__c sig = querySig(KEY_SIGSTANDARD);
            
            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>{
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_DRAFT, sig.Id, con.Id),        // 0
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sig.Id, con.Id),    // 1
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REVIEWING, sig.Id, con.Id),     // 2
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sig.Id, con.Id),      // 3
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_OFFER, sig.Id, con.Id),         // 4
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REJECTED, sig.Id, con.Id),      // 5
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sig.Id, con.Id),     // 6
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REVIEWING, sig.Id, con.Id),     // 7
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_CANCELLED, sig.Id, con.Id),     // 8
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sig.Id, con.Id)       // 9
            };
            insert ipas;
            
            reduivy__Study_Intake_Group__c sigAfterInsert = querySig(KEY_SIGSTANDARD);
            
            System.Assert.areEqual(8, sigAfterInsert.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after insert');
            System.Assert.areEqual(3, sigAfterInsert.reduivy__Approved_Applications__c, 'Approved Applications wrong after insert');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterInsert, FIELD_ACCEPTED_APPLICATIONS), 'Accepted Applications should be empty, actual: ' + sigAfterInsert.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.areEqual(1, sigAfterInsert.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after insert');
            System.Assert.areEqual(2, sigAfterInsert.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after insert');
            System.Assert.areEqual(
                sigAfterInsert.reduivy__Accepted_Applications__c, 
                sigAfterInsert.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after insert'
            );
            
            // Now update 5 of the IPAs
            ipas[1].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING;       // Submitted -> Reviewing
            ipas[2].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;        // Reviewing -> Approved
            ipas[4].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;  // Offer -> Offer Accepted
            ipas[7].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;        // Reviewing -> Approved
            ipas[8].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_CANCELLED;       // Cancelled -> Cancelled (still no rollup)
            update ipas;
            
            reduivy__Study_Intake_Group__c sigAfterUpdate = querySig(KEY_SIGSTANDARD);
            
            System.Assert.areEqual(8, sigAfterUpdate.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after update');
            System.Assert.areEqual(5, sigAfterUpdate.reduivy__Approved_Applications__c, 'Approved Applications wrong after update');
            System.Assert.areEqual(1, sigAfterUpdate.reduivy__Accepted_Applications__c, 'Accepted Applications wrong after update');
            System.Assert.areEqual(1, sigAfterUpdate.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after update');
            System.Assert.areEqual(1, sigAfterUpdate.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after update');
            System.Assert.areEqual(
                sigAfterUpdate.reduivy__Accepted_Applications__c, 
                sigAfterUpdate.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after update'
            );
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description Test inserting 10 IPA with random statuses, updating 5 IPA, and asserting Study Intake rollups.
     */
    @IsTest
    static void testSigAsStudent_InsertAndUpdateMultipleIpaStatuses_2() {
        User studentUser = testFactory.getStudentUser();
        
        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        System.runAs(studentUser) {
            Contact con = getCon();
            reduivy__Study_Intake_Group__c sig = querySig(KEY_SIGSTANDARD);
            
            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>{
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sig.Id, con.Id),    // 0
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sig.Id, con.Id),    // 1
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REVIEWING, sig.Id, con.Id),     // 2
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sig.Id, con.Id),      // 3
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sig.Id, con.Id),      // 4
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REJECTED, sig.Id, con.Id),      // 5
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REJECTED, sig.Id, con.Id),      // 6
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REVIEWING, sig.Id, con.Id),     // 7
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_CANCELLED, sig.Id, con.Id),     // 8
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_DRAFT, sig.Id, con.Id)          // 9
            };
            insert ipas;
            
            reduivy__Study_Intake_Group__c sigAfterInsert = querySig(KEY_SIGSTANDARD);
            
            System.Assert.areEqual(8, sigAfterInsert.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after insert');
            System.Assert.areEqual(2, sigAfterInsert.reduivy__Approved_Applications__c, 'Approved Applications wrong after insert');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterInsert, FIELD_ACCEPTED_APPLICATIONS), 'Accepted Applications should be empty, actual: ' + sigAfterInsert.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.areEqual(2, sigAfterInsert.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after insert');
            System.Assert.areEqual(2, sigAfterInsert.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after insert');
            System.Assert.areEqual(
                sigAfterInsert.reduivy__Accepted_Applications__c, 
                sigAfterInsert.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after insert'
            );
            
            // Update
            ipas[0].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING;       // Submitted -> Reviewing
            ipas[2].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;        // Reviewing -> Approved
            ipas[4].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;  // Approved -> Offer Accepted
            ipas[6].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_CANCELLED;       // Rejected -> Cancelled
            ipas[9].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_CANCELLED;       // Draft -> Cancelled
            update ipas;
            
            reduivy__Study_Intake_Group__c sigAfterUpdate = querySig(KEY_SIGSTANDARD);
            
            System.Assert.areEqual(7, sigAfterUpdate.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after update');
            System.Assert.areEqual(3, sigAfterUpdate.reduivy__Approved_Applications__c, 'Approved Applications wrong after update');
            System.Assert.areEqual(1, sigAfterUpdate.reduivy__Accepted_Applications__c, 'Accepted Applications wrong after update');
            System.Assert.areEqual(1, sigAfterUpdate.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after update');
            System.Assert.areEqual(2, sigAfterUpdate.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after update');
            System.Assert.areEqual(
                sigAfterUpdate.reduivy__Accepted_Applications__c, 
                sigAfterUpdate.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after update'
            );
                 
            
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }


    /**
     * @description Test inserting 10 IPA with random statuses, updating 5 IPA, and asserting Study Intake rollups.
     */
    @IsTest
    static void testSigAsStudent_InsertAndUpdateMultipleIpaStatuses_3() {
        User studentUser = testFactory.getStudentUser();
        
        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        System.runAs(studentUser) {
            Contact con = getCon();
            reduivy__Study_Intake_Group__c sig = querySig(KEY_SIGSTANDARD);
            
            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>{
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_DRAFT, sig.Id, con.Id),           // 0
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sig.Id, con.Id),       // 1
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sig.Id, con.Id),       // 2
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REVIEWING, sig.Id, con.Id),        // 3
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sig.Id, con.Id),         // 4
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REJECTED, sig.Id, con.Id),         // 5
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REJECTED, sig.Id, con.Id),         // 6
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REVIEWING, sig.Id, con.Id),        // 7
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_CANCELLED, sig.Id, con.Id),        // 8
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sig.Id, con.Id)          // 9
            };
            insert ipas;
            
            reduivy__Study_Intake_Group__c sigAfterInsert = querySig(KEY_SIGSTANDARD);
            
            System.Assert.areEqual(8, sigAfterInsert.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after insert');
            System.Assert.areEqual(2, sigAfterInsert.reduivy__Approved_Applications__c, 'Approved Applications wrong after insert');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterInsert, FIELD_ACCEPTED_APPLICATIONS), 'Accepted Applications should be empty, actual: ' + sigAfterInsert.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.areEqual(2, sigAfterInsert.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after insert');
            System.Assert.areEqual(2, sigAfterInsert.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after insert');
            System.Assert.areEqual(
                sigAfterInsert.reduivy__Accepted_Applications__c, 
                sigAfterInsert.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after insert'
            );
            
            // Update
            ipas[1].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING;        // Submitted -> Reviewing
            ipas[2].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING;        // Submitted -> Reviewing
            ipas[4].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;   // Approved -> Offer Accepted
            ipas[5].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_CANCELLED;        // Rejected -> Cancelled
            ipas[7].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;         // Reviewing -> Approved
            update ipas;
            
            reduivy__Study_Intake_Group__c sigAfterUpdate = querySig(KEY_SIGSTANDARD);
            
            System.Assert.areEqual(7, sigAfterUpdate.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after update');
            System.Assert.areEqual(3, sigAfterUpdate.reduivy__Approved_Applications__c, 'Approved Applications wrong after update');
            System.Assert.areEqual(1, sigAfterUpdate.reduivy__Accepted_Applications__c, 'Accepted Applications wrong after update');
            System.Assert.areEqual(1, sigAfterUpdate.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after update');
            System.Assert.areEqual(3, sigAfterUpdate.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after update');
            System.Assert.areEqual(
                sigAfterUpdate.reduivy__Accepted_Applications__c, 
                sigAfterUpdate.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after update'
            );
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description Test inserting 10 IPA with random statuses, updating 5 IPA, and asserting Study Intake rollups.
     */
    @IsTest
    static void testSigAsStudent_InsertAndUpdateMultipleIpaStatuses_4() {
        User studentUser = testFactory.getStudentUser();
        
        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        System.runAs(studentUser) {
            Contact con = getCon();
            reduivy__Study_Intake_Group__c sig = querySig(KEY_SIGSTANDARD);
            
            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>{
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_DRAFT, sig.Id, con.Id),           // 0
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sig.Id, con.Id),       // 1
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sig.Id, con.Id),       // 2
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REVIEWING, sig.Id, con.Id),        // 3
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sig.Id, con.Id),         // 4
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REJECTED, sig.Id, con.Id),         // 5
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REJECTED, sig.Id, con.Id),         // 6
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REVIEWING, sig.Id, con.Id),        // 7
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_CANCELLED, sig.Id, con.Id),        // 8
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sig.Id, con.Id)          // 9
            };
            insert ipas;
            
            reduivy__Study_Intake_Group__c sigAfterInsert = querySig(KEY_SIGSTANDARD);
            
            System.Assert.areEqual(8, sigAfterInsert.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after insert');
            System.Assert.areEqual(2, sigAfterInsert.reduivy__Approved_Applications__c, 'Approved Applications wrong after insert');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterInsert, FIELD_ACCEPTED_APPLICATIONS), 'Accepted Applications should be empty, actual: ' + sigAfterInsert.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.areEqual(2, sigAfterInsert.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after insert');
            System.Assert.areEqual(2, sigAfterInsert.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after insert');
            System.Assert.areEqual(
                sigAfterInsert.reduivy__Accepted_Applications__c, 
                sigAfterInsert.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after insert'
            );
            
            // Update
            ipas[1].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING;        // Submitted -> Reviewing
            ipas[2].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REJECTED;         // Submitted -> Rejected
            ipas[4].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;   // Approved -> Offer Accepted
            ipas[5].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_CANCELLED;        // Rejected -> Cancelled
            ipas[7].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;         // Reviewing -> Approved
            update ipas;
            
            reduivy__Study_Intake_Group__c sigAfterUpdate = querySig(KEY_SIGSTANDARD);
            
            System.Assert.areEqual(7, sigAfterUpdate.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after update');
            System.Assert.areEqual(3, sigAfterUpdate.reduivy__Approved_Applications__c, 'Approved Applications wrong after update');
            System.Assert.areEqual(1, sigAfterUpdate.reduivy__Accepted_Applications__c, 'Accepted Applications wrong after update');
            System.Assert.areEqual(2, sigAfterUpdate.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after update');
            System.Assert.areEqual(2, sigAfterUpdate.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after update');
            System.Assert.areEqual(
                sigAfterUpdate.reduivy__Accepted_Applications__c, 
                sigAfterUpdate.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after update'
            );
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description Test inserting 10 IPA with random statuses, updating 5 IPA, and asserting Study Intake rollups.
     */
    @IsTest
    static void testSigAsStudent_InsertAndUpdateMultipleIpaStatuses_5() {
        User studentUser = testFactory.getStudentUser();
        
        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        System.runAs(studentUser) {
            Contact con = getCon();
            reduivy__Study_Intake_Group__c sig = querySig(KEY_SIGSTANDARD);
            
            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>{
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_DRAFT, sig.Id, con.Id),           // 0
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sig.Id, con.Id),       // 1
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REVIEWING, sig.Id, con.Id),        // 2
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sig.Id, con.Id),         // 3
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_OFFER, sig.Id, con.Id),            // 4
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REJECTED, sig.Id, con.Id),         // 5
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REVIEWING, sig.Id, con.Id),        // 6
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sig.Id, con.Id),         // 7
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_CANCELLED, sig.Id, con.Id),        // 8
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REJECTED, sig.Id, con.Id)          // 9
            };
            insert ipas;
            
            reduivy__Study_Intake_Group__c sigAfterInsert = querySig(KEY_SIGSTANDARD);
            
            System.Assert.areEqual(8, sigAfterInsert.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after insert');
            System.Assert.areEqual(3, sigAfterInsert.reduivy__Approved_Applications__c, 'Approved Applications wrong after insert');
            System.Assert.isTrue(sigFieldIsEmpty(sigAfterInsert, FIELD_ACCEPTED_APPLICATIONS), 'Accepted Applications should be empty, actual: ' + sigAfterInsert.get(FIELD_ACCEPTED_APPLICATIONS));
            System.Assert.areEqual(2, sigAfterInsert.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after insert');
            System.Assert.areEqual(2, sigAfterInsert.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after insert');
            System.Assert.areEqual(
                sigAfterInsert.reduivy__Accepted_Applications__c, 
                sigAfterInsert.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after insert'
            );
            
            // Update
            ipas[1].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REVIEWING;        // Submitted -> Reviewing
            ipas[2].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_APPROVED;         // Reviewing -> Approved
            ipas[4].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;   // Offer -> Offer Accepted
            ipas[5].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_CANCELLED;        // Rejected -> Cancelled
            ipas[7].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_REJECTED;         // Approved -> Rejected
            update ipas;
            
            reduivy__Study_Intake_Group__c sigAfterUpdate = querySig(KEY_SIGSTANDARD);
            
            System.Assert.areEqual(7, sigAfterUpdate.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after update');
            System.Assert.areEqual(3, sigAfterUpdate.reduivy__Approved_Applications__c, 'Approved Applications wrong after update');
            System.Assert.areEqual(1, sigAfterUpdate.reduivy__Accepted_Applications__c, 'Accepted Applications wrong after update');
            System.Assert.areEqual(2, sigAfterUpdate.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after update');
            System.Assert.areEqual(2, sigAfterUpdate.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after update');
            System.Assert.areEqual(
                sigAfterUpdate.reduivy__Accepted_Applications__c, 
                sigAfterUpdate.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after update'
            );
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description Test inserting 10 IPA with random statuses, updating 5 IPA, and asserting Study Intake rollups. Over capacity is tested
     */
    @IsTest
    static void testSigAsStudent_InsertAndUpdateMultipleIpaStatuses_OverCapacity() {
        User studentUser = testFactory.getStudentUser();
        setEnableSigSetting(true);
        Test.startTest();        
        REDU_TriggerController.muteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        System.runAs(studentUser) {
            Contact con = getCon();
            reduivy__Study_Intake_Group__c sig = querySig(KEY_SIGSTANDARD);
            
            List<reduivy__Individual_Program_Application__c> ipas = new List<reduivy__Individual_Program_Application__c>{
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_DRAFT, sig.Id, con.Id),           // 0
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_SUBMITTED, sig.Id, con.Id),       // 1
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REVIEWING, sig.Id, con.Id),        // 2
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED, sig.Id, con.Id),   // 3
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sig.Id, con.Id),         // 4
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sig.Id, con.Id),         // 5
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REVIEWING, sig.Id, con.Id),        // 6
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_APPROVED, sig.Id, con.Id),         // 7
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_CANCELLED, sig.Id, con.Id),        // 8
                newIpaWithSig(IPA_Helper.APPLICATION_STATUS_REJECTED, sig.Id, con.Id)          // 9
            };
            insert ipas;
            
            reduivy__Study_Intake_Group__c sigAfterInsert = querySig(KEY_SIGSTANDARD);
            
            System.Assert.areEqual(8, sigAfterInsert.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after insert');
            System.Assert.areEqual(4, sigAfterInsert.reduivy__Approved_Applications__c, 'Approved Applications wrong after insert');
            System.Assert.areEqual(1, sigAfterInsert.reduivy__Accepted_Applications__c, 'Accepted Applications wrong after insert');
            System.Assert.areEqual(1, sigAfterInsert.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after insert');
            System.Assert.areEqual(2, sigAfterInsert.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after insert');
            System.Assert.areEqual(
                sigAfterInsert.reduivy__Accepted_Applications__c, 
                sigAfterInsert.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after insert'
            );
            
            // Update
            ipas[1].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;      // Submitted -> OFFER_ACCEPTED
            ipas[2].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;      // Reviewing -> OFFER_ACCEPTED
            ipas[4].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;      // Offer -> OFFER_ACCEPTED
            ipas[5].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;      // Rejected -> OFFER_ACCEPTED
            ipas[7].reduivy__Application_Status__c = IPA_Helper.APPLICATION_STATUS_OFFER_ACCEPTED;      // Approved -> OFFER_ACCEPTED


            try{
                update ipas;
                System.Assert.fail('Should be failed as the booked places is full! Booked Places: ' + sigAfterInsert.reduivy__Booked_Places__c);
            } catch(Exception exp) {
                String errorMsg = String.format(Label.Error_No_Available_Places_Remaining_In_Study_Intake_Group, new List<String> {
                    SIT_Helper.getObjectLabel(), sigAfterInsert.Name
                });

                System.Assert.isTrue(exp.getMessage().contains(errorMsg), 'Wrong error message! Expected: ' + errorMsg + ', Actual: ' + exp.getMessage());
                
            }
            
            reduivy__Study_Intake_Group__c sigAfterUpdate = querySig(KEY_SIGSTANDARD);
            
            System.Assert.areEqual(8, sigAfterUpdate.reduivy__Submitted_Applications__c, 'Submitted Applications wrong after insert');
            System.Assert.areEqual(4, sigAfterUpdate.reduivy__Approved_Applications__c, 'Approved Applications wrong after insert');
            System.Assert.areEqual(1, sigAfterUpdate.reduivy__Accepted_Applications__c, 'Accepted Applications wrong after insert');
            System.Assert.areEqual(1, sigAfterUpdate.reduivy__Rejected_Applications__c, 'Rejected Applications wrong after insert');
            System.Assert.areEqual(2, sigAfterUpdate.reduivy__Reviewing_Applications__c, 'Reviewing Applications wrong after insert');
            System.Assert.areEqual(
                sigAfterUpdate.reduivy__Accepted_Applications__c, 
                sigAfterUpdate.reduivy__Booked_Places__c,
                'Booked Places must match Accepted Applications after insert'
            );
        }
        REDU_TriggerController.unmuteTriggers(new Set<String>{'IPA_PreventDuplicate_EXE'});
        Test.stopTest();        
    }

    /**
     * @description Init a new IPA to insert
     * @param  applicationStatus Application status
     * @param  sitId             study intake id
     * @param  contactId         student contact id
     * @return                   new Individual Program Application
     */
    static reduivy__Individual_Program_Application__c newIpaWithSit(String applicationStatus, String sitId, String contactId) {
        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c();
        ipa.reduivy__Application_Status__c = applicationStatus;
        ipa.reduivy__Study_Intake__c = sitId;
        ipa.reduivy__Study_Program__c = getSpg().Id;
        ipa.reduivy__Application_Date__c = System.today();
        ipa.reduivy__Contact__c = contactId;
        
        return ipa;
    }
    /**
     * @description Init a new IPA to insert
     * @param  applicationStatus Application status
     * @param  sitId             study intake id
     * @param  contactId         student contact id
     * @return                   new Individual Program Application
     */
    static reduivy__Individual_Program_Application__c newIpaWithSig(String applicationStatus, String sigId, String contactId) {
        reduivy__Individual_Program_Application__c ipa = new reduivy__Individual_Program_Application__c();
        ipa.reduivy__Application_Status__c = applicationStatus;
        ipa.reduivy__Study_Intake_Group__c = sigId;
        ipa.reduivy__Study_Program__c = getSpg().Id;
        ipa.reduivy__Application_Date__c = System.today();
        ipa.reduivy__Contact__c = contactId;
        
        return ipa;
    }

    /**
     * @description get Study Program
     * @return   BACBIS Study Program
     */
    static reduivy__Study_Program__c getSpg() {
        if(spgRecord == null) {
            spgRecord = querySpg();
        }
        return spgRecord;
    }

    /**
     * @description query for Study Program
     * @return   BACBIS Study Program from database
     */
    static reduivy__Study_Program__c querySpg(){
        return [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = :KEY_SPG LIMIT 1];
    }

    /**
     * @description query for Study Intake
     * @param  key the study intake sample record key
     * @return     Study intake
     */
    static reduivy__Study_Intake__c querySit(String key) { 
        reduivy__Study_Intake__c sit = [
            SELECT Id, Name, reduivy__Capacity__c, reduivy__Booked_Places__c,
            reduivy__Submitted_Applications__c,
            reduivy__Approved_Applications__c,
            reduivy__Accepted_Applications__c,
            reduivy__Rejected_Applications__c,
            reduivy__Reviewing_Applications__c,
            reduivy__Available_Places__c
            FROM reduivy__Study_Intake__c
            WHERE reduivy__Sample_Record_Code__c = :key
            LIMIT 1
        ];

        return sit;
    }

    /**
     * @description get student contact
     * @param  key the student contact key
     * @return     student contact
     */
    static Contact getCon() {
        return [SELECT Id FROM Contact WHERE reduivy__Sample_Record_Code__c = :KEY_CONTACT LIMIT 1];
    }

    /**
     * @description check if booked places is empty
     * @param  sit study intake
     * @return     return true if booked places is empty
     */
    static Boolean sitApplicationFieldsAreEmpty(reduivy__Study_Intake__c sit){
        return 
            (sit.reduivy__Booked_Places__c == 0 || sit.reduivy__Booked_Places__c == null) &&
            (sit.reduivy__Submitted_Applications__c == 0 || sit.reduivy__Submitted_Applications__c == null) &&
            (sit.reduivy__Approved_Applications__c == 0 || sit.reduivy__Approved_Applications__c == null) &&
            (sit.reduivy__Accepted_Applications__c == 0 || sit.reduivy__Accepted_Applications__c == null) &&
            (sit.reduivy__Reviewing_Applications__c == 0 || sit.reduivy__Reviewing_Applications__c == null) &&
            (sit.reduivy__Rejected_Applications__c == 0 || sit.reduivy__Rejected_Applications__c == null);
    }

    /**
     * @description check if booked places is empty
     * @param  sit study intake
     * @return     return true if booked places is empty
     */
    static Boolean sigApplicationFieldsAreEmpty(reduivy__Study_Intake_Group__c sig){
        return 
            (sig.reduivy__Booked_Places__c == 0 || sig.reduivy__Booked_Places__c == null) &&
            (sig.reduivy__Submitted_Applications__c == 0 || sig.reduivy__Submitted_Applications__c == null) &&
            (sig.reduivy__Approved_Applications__c == 0 || sig.reduivy__Approved_Applications__c == null) &&
            (sig.reduivy__Accepted_Applications__c == 0 || sig.reduivy__Accepted_Applications__c == null) &&
            (sig.reduivy__Reviewing_Applications__c == 0 || sig.reduivy__Reviewing_Applications__c == null) &&
            (sig.reduivy__Rejected_Applications__c == 0 || sig.reduivy__Rejected_Applications__c == null);
    }

    static String sitApplicationFieldsNotEmptyErrorMsg(reduivy__Study_Intake__c sit){
        return 'Study Intake should be empty!\n' +
            FIELD_BOOKED_PLACES + ': ' + sit.get(FIELD_BOOKED_PLACES) + '\n' +
            FIELD_SUBMITTED_APPLICATIONS + ': ' + sit.get(FIELD_SUBMITTED_APPLICATIONS) + '\n' +
            FIELD_APPROVED_APPLICATIONS + ': ' + sit.get(FIELD_APPROVED_APPLICATIONS) + '\n' +
            FIELD_ACCEPTED_APPLICATIONS + ': ' + sit.get(FIELD_ACCEPTED_APPLICATIONS) + '\n' +
            FIELD_REJECTED_APPLICATIONS + ': ' + sit.get(FIELD_REJECTED_APPLICATIONS) + '\n' +
            FIELD_REVIEWING_APPLICATIONS + ': ' + sit.get(FIELD_REVIEWING_APPLICATIONS) + '\n';
    }

    static String sigApplicationFieldsNotEmptyErrorMsg(reduivy__Study_Intake_Group__c sig){
        return 'Study Intake should be empty!\n' +
            FIELD_BOOKED_PLACES + ': ' + sig.get(FIELD_BOOKED_PLACES) + '\n' +
            FIELD_SUBMITTED_APPLICATIONS + ': ' + sig.get(FIELD_SUBMITTED_APPLICATIONS) + '\n' +
            FIELD_APPROVED_APPLICATIONS + ': ' + sig.get(FIELD_APPROVED_APPLICATIONS) + '\n' +
            FIELD_ACCEPTED_APPLICATIONS + ': ' + sig.get(FIELD_ACCEPTED_APPLICATIONS) + '\n' +
            FIELD_REJECTED_APPLICATIONS + ': ' + sig.get(FIELD_REJECTED_APPLICATIONS) + '\n' +
            FIELD_REVIEWING_APPLICATIONS + ': ' + sig.get(FIELD_REVIEWING_APPLICATIONS) + '\n';
    }

    static Boolean sitFieldIsEmpty(reduivy__Study_Intake__c sit, String fieldName) {
        return (sit.get(fieldName) == 0) || (sit.get(fieldName) == null);
    }

    static Boolean sigFieldIsEmpty(reduivy__Study_Intake_Group__c sig, String fieldName) {
        return (sig.get(fieldName) == 0) || (sig.get(fieldName) == null);
    }

    static String getSitInvalidFieldErrorMessage() { 
        return String.format(Label.IdvPa_Application_Status_Rollup_Field_Is_Not_Configured_Invalid,
            new List<String>{
                String.join(
                    new List<String> {
                        IPA_Helper.APPLICATION_STATUS_DRAFT,
                        IPA_Helper.APPLICATION_STATUS_SUBMITTED,
                        IPA_Helper.APPLICATION_STATUS_APPROVED
                    },
                ', '
                )
            }
        );
    }
	
    static String getSigInvalidFieldErrorMessage() { 
        return String.format(Label.IdvPa_Application_Status_Rollup_Field_Is_Not_Configured_Invalid,
            new List<String>{
                String.join(
                    new List<String> {
                        IPA_Helper.APPLICATION_STATUS_DRAFT,
                        IPA_Helper.APPLICATION_STATUS_SUBMITTED,
                        IPA_Helper.APPLICATION_STATUS_APPROVED
                    },
                ', '
                )
            }
        );
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
    
    /**
     * @description query for Study Intake group
     * @param  key the study intake sample record key
     * @return     Study intake
     */
    static reduivy__Study_Intake_Group__c querySig(String key) { 
        reduivy__Study_Intake_Group__c sig = [
            SELECT Id, Name, reduivy__Capacity__c, reduivy__Booked_Places__c,
            reduivy__Submitted_Applications__c,
            reduivy__Approved_Applications__c,
            reduivy__Accepted_Applications__c,
            reduivy__Rejected_Applications__c,
            reduivy__Reviewing_Applications__c,
            reduivy__Available_Places__c
            FROM reduivy__Study_Intake_Group__c
            WHERE reduivy__Sample_Record_Code__c = :key
            LIMIT 1
        ];

        return sig;
    }

}