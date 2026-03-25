/**
 * @author      WDCi (XiRouh)
 * @date        January 2026
 * @group       Test
 * @description Test class for IRS_UpdateParentCompletionIndicator_EXE
 * @changehistory
 * ISS-002675 06-01-2026 XiRouh - new class
 */
@IsTest
public inherited sharing class IRS_UpdateParentCompletionIndicator_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
    static final String SRS_LOCAL = 'SRS_Local';
    static final String SRS_GENERAL = 'SRS_General';
    static final String SRS_APPLICATION = 'SRS_Application';
    
    static final String IPA_CREATE_IRS_STATUS = 'Submitted';
    static final String BIS_SPG_PROGRAM_CODE = 'BACBIS';

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
            
            // This will create SRS, SRQ, IPA with IRS and IRQ automatically
            testFactory.initMasterData(SRQ_Helper.getApiName());
            testFactory.initOfferingData(SIT_Helper.getApiName());
            testFactory.initFacultyData(USR_Helper.getApiName(), true);
            testFactory.initStudentData(IRQ_Helper.getApiName(), true);

            // Update SRS with completion indicator fields
            for (reduivy__Study_Requirement_Set__c srs : testFactory.studyRequirementSets.values()) {
                srs.reduivy__Completion_Indicator_Admin__c = 'reduivy__Test_Requirements_Complete_Admin__c';
                srs.reduivy__Completion_Indicator_Faculty__c = 'reduivy__Test_Requirements_Complete_Faculty__c';
                srs.reduivy__Completion_Indicator_Student__c = 'reduivy__Test_Requirements_Complete_Student__c';
            }
            REDU_SystemMode_UTIL.doUpdate(testFactory.studyRequirementSets.values());

            Test.stopTest();
        }
    }

    /**
     * @description Test all requirements complete in all IRS - should set indicators to true as admin
     */
    @IsTest
    static void testForUpdate_AllIRSComplete_AllIndicatorsTrue_AsAdmin() {

        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA()){
            return;
        }

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Program_Application__c ipa = (reduivy__Individual_Program_Application__c)testData.get('ipa');
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');
        reduivy__Individual_Requirement_Set__c irsGeneral = (reduivy__Individual_Requirement_Set__c)testData.get('irsGeneral');
        reduivy__Individual_Requirement_Set__c irsApplication = (reduivy__Individual_Requirement_Set__c)testData.get('irsApplication');

        // Verify initial state - all indicators should be false
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(false, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 'Admin indicator should be false initially!');
        System.Assert.areEqual(false, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Faculty__c'), 'Faculty indicator should be false initially!');
        System.Assert.areEqual(false, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Student__c'), 'Student indicator should be false initially!');

        System.runAs(ADMIN_USER) {
            // Complete all requirements in irsGeneral (Admin visibility)
            for (reduivy__Individual_Requirement__c irq : irsGeneral.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsGeneral.reduivy__Individual_Requirements__r;
        }

        // Verify admin indicator is still false (irsLocal and irsApplication not complete yet)
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(false, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 'Admin indicator should be false with two IRS incomplete!');

        System.runAs(ADMIN_USER) {
            // Complete all requirements in irsLocal (Admin visibility)
            for (reduivy__Individual_Requirement__c irq : irsLocal.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsLocal.reduivy__Individual_Requirements__r;
        }

        // Verify admin indicator is still false (irsApplication not complete yet)
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(false, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 'Admin indicator should be false with one IRS incomplete!');

        System.runAs(ADMIN_USER) {
            // Complete all requirements in irsApplication (Admin visibility)
            for (reduivy__Individual_Requirement__c irq : irsApplication.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsApplication.reduivy__Individual_Requirements__r;
        }
        
        // Verify admin indicator is now true (all 3 IRS complete)
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 'Admin indicator should be true with all IRS complete!');

        Test.stopTest();
    }

    /**
     * @description Test one IRS incomplete - should keep indicator false  as admin
     */
    @IsTest
    static void testForUpdate_OneIRSIncomplete_IndicatorFalse_AsAdmin() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA()){
            return;
        }

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Program_Application__c ipa = (reduivy__Individual_Program_Application__c)testData.get('ipa');
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');
        reduivy__Individual_Requirement_Set__c irsGeneral = (reduivy__Individual_Requirement_Set__c)testData.get('irsGeneral');
        reduivy__Individual_Requirement_Set__c irsApplication = (reduivy__Individual_Requirement_Set__c)testData.get('irsApplication');
        
        System.runAs(ADMIN_USER) {
            // Complete all requirements in irsGeneral
            for (reduivy__Individual_Requirement__c irq : irsGeneral.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsGeneral.reduivy__Individual_Requirements__r;

            // Complete all requirements in irsApplication
            for (reduivy__Individual_Requirement__c irq : irsApplication.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsApplication.reduivy__Individual_Requirements__r;

            // Leave irsLocal incomplete (complete all except the last one if multiple requirements exist)
            if (irsLocal.reduivy__Individual_Requirements__r.size() > 1) {
                List<reduivy__Individual_Requirement__c> localIrqsToComplete = new List<reduivy__Individual_Requirement__c>();
                for (Integer i = 0; i < irsLocal.reduivy__Individual_Requirements__r.size() - 1; i++) {
                    reduivy__Individual_Requirement__c irq = irsLocal.reduivy__Individual_Requirements__r[i];
                    irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                    irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
                    localIrqsToComplete.add(irq);
                }
                if (!localIrqsToComplete.isEmpty()) {
                    update localIrqsToComplete;
                }
            }
        }

        // Verify admin indicator is false (one IRS incomplete)
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(false, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 'Admin indicator should be false when any IRS incomplete!');

        Test.stopTest();
    }

    /**
     * @description Test Faculty visibility - complete all Faculty visible requirements as admin
     */
    @IsTest
    static void testForUpdate_FacultyVisibility_AllComplete_IndicatorTrue_AsAdmin() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA()){
            return;
        }

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Program_Application__c ipa = (reduivy__Individual_Program_Application__c)testData.get('ipa');
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');
        reduivy__Individual_Requirement_Set__c irsGeneral = (reduivy__Individual_Requirement_Set__c)testData.get('irsGeneral');
        reduivy__Individual_Requirement_Set__c irsApplication = (reduivy__Individual_Requirement_Set__c)testData.get('irsApplication');
        
        System.runAs(ADMIN_USER) {
            // Set all requirements to Faculty visibility and complete them
            for (reduivy__Individual_Requirement__c irq : irsGeneral.reduivy__Individual_Requirements__r) {
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_FACULTY;
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
            }
            update irsGeneral.reduivy__Individual_Requirements__r;

            for (reduivy__Individual_Requirement__c irq : irsLocal.reduivy__Individual_Requirements__r) {
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_FACULTY;
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
            }
            update irsLocal.reduivy__Individual_Requirements__r;

            for (reduivy__Individual_Requirement__c irq : irsApplication.reduivy__Individual_Requirements__r) {
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_FACULTY;
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
            }
            update irsApplication.reduivy__Individual_Requirements__r;
        }

        // Verify Faculty indicator is true
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Faculty__c'), 'Faculty indicator should be true with all Faculty requirements complete!');

        Test.stopTest();
    }

    /**
     * @description Test Student visibility - complete all Student visible requirements as admin
     */
    @IsTest
    static void testForUpdate_StudentVisibility_AllComplete_IndicatorTrue_AsAdmin() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA()){
            return;
        }
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Program_Application__c ipa = (reduivy__Individual_Program_Application__c)testData.get('ipa');
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');
        reduivy__Individual_Requirement_Set__c irsGeneral = (reduivy__Individual_Requirement_Set__c)testData.get('irsGeneral');
        reduivy__Individual_Requirement_Set__c irsApplication = (reduivy__Individual_Requirement_Set__c)testData.get('irsApplication');
        
        System.runAs(ADMIN_USER) {
            // Set all requirements to Student visibility and submit them
            for (reduivy__Individual_Requirement__c irq : irsGeneral.reduivy__Individual_Requirements__r) {
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT;
                irq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
            }
            update irsGeneral.reduivy__Individual_Requirements__r;

            for (reduivy__Individual_Requirement__c irq : irsLocal.reduivy__Individual_Requirements__r) {
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT;
                irq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
            }
            update irsLocal.reduivy__Individual_Requirements__r;

            for (reduivy__Individual_Requirement__c irq : irsApplication.reduivy__Individual_Requirements__r) {
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT;
                irq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
            }
            update irsApplication.reduivy__Individual_Requirements__r;
        }

        // Verify Student indicator is true
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Student__c'), 'Student indicator should be true with all Student requirements submitted!');

        Test.stopTest();
    }

    /**
     * @description Test mixed visibility - verify each indicator tracks its own requirements as admin
     */
    @IsTest
    static void testForUpdate_MixedVisibility_IndependentIndicators_AsAdmin() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA()){
            return;
        }
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Program_Application__c ipa = (reduivy__Individual_Program_Application__c)testData.get('ipa');
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');
        reduivy__Individual_Requirement_Set__c irsGeneral = (reduivy__Individual_Requirement_Set__c)testData.get('irsGeneral');
        reduivy__Individual_Requirement_Set__c irsApplication = (reduivy__Individual_Requirement_Set__c)testData.get('irsApplication');
        
        System.runAs(ADMIN_USER) {
            // irsGeneral: Set requirements to different visibilities and complete them
            List<reduivy__Individual_Requirement__c> generalIrqs = irsGeneral.reduivy__Individual_Requirements__r;
            if (generalIrqs.size() > 0) {
                // Set first requirement to Admin
                generalIrqs[0].reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
                generalIrqs[0].reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                
                // Set remaining requirements to Faculty
                for (Integer i = 1; i < generalIrqs.size(); i++) {
                    generalIrqs[i].reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_FACULTY;
                    generalIrqs[i].reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                }
            }
            update generalIrqs;

            // irsLocal: Set requirements to different visibilities
            List<reduivy__Individual_Requirement__c> localIrqs = irsLocal.reduivy__Individual_Requirements__r;
            if (localIrqs.size() > 0) {
                // Set first requirement to Admin
                localIrqs[0].reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
                localIrqs[0].reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                
                // Set remaining requirements to Student
                for (Integer i = 1; i < localIrqs.size(); i++) {
                    localIrqs[i].reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT;
                    localIrqs[i].reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
                    localIrqs[i].reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                }
            }
            update localIrqs;

            // irsApplication: Set all to Admin and complete them
            for (reduivy__Individual_Requirement__c irq : irsApplication.reduivy__Individual_Requirements__r) {
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
            }
            update irsApplication.reduivy__Individual_Requirements__r;
        }

        // Verify indicators
        ipa = queryIPA(ipa.Id);
        // Admin: All 3 IRS have Admin requirements complete
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 'Admin indicator should be true!');
        // Faculty: Only irsGeneral has Faculty requirements complete, others have none
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Faculty__c'), 'Faculty indicator should be true!');
        // Student: Only irsLocal has Student requirements complete, others have none
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Student__c'), 'Student indicator should be true!');

        Test.stopTest();
    }

    /**
     * @description Test changing requirement from complete to incomplete as admin
     */
    @IsTest
    static void testForUpdate_RevertCompletion_IndicatorsFalse_AsAdmin() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA()){
            return;
        }
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Program_Application__c ipa = (reduivy__Individual_Program_Application__c)testData.get('ipa');
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');
        reduivy__Individual_Requirement_Set__c irsGeneral = (reduivy__Individual_Requirement_Set__c)testData.get('irsGeneral');
        reduivy__Individual_Requirement_Set__c irsApplication = (reduivy__Individual_Requirement_Set__c)testData.get('irsApplication');
        
        System.runAs(ADMIN_USER) {
            // Complete all requirements in all IRS
            for (reduivy__Individual_Requirement__c irq : irsGeneral.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsGeneral.reduivy__Individual_Requirements__r;

            for (reduivy__Individual_Requirement__c irq : irsLocal.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsLocal.reduivy__Individual_Requirements__r;

            for (reduivy__Individual_Requirement__c irq : irsApplication.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsApplication.reduivy__Individual_Requirements__r;
        }

        // Verify indicator is true
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 'Admin indicator should be true!');

        System.runAs(ADMIN_USER) {
            // Revert any one requirement to incomplete
            if (!irsLocal.reduivy__Individual_Requirements__r.isEmpty()) {
                reduivy__Individual_Requirement__c irqToRevert = irsLocal.reduivy__Individual_Requirements__r[0];
                irqToRevert.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_OPEN;
                update irqToRevert;
            }
        }

        // Verify indicator is now false
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(false, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 'Admin indicator should be false after reverting!');

        Test.stopTest();
    }

    /**
     * @description Test inactive IRS is ignored in completion calculation as admin
     */
    @IsTest
    static void testForUpdate_InactiveIRS_Ignored_AsAdmin() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA()){
            return;
        }
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Program_Application__c ipa = (reduivy__Individual_Program_Application__c)testData.get('ipa');
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');
        reduivy__Individual_Requirement_Set__c irsGeneral = (reduivy__Individual_Requirement_Set__c)testData.get('irsGeneral');
        reduivy__Individual_Requirement_Set__c irsApplication = (reduivy__Individual_Requirement_Set__c)testData.get('irsApplication');
        
        System.runAs(ADMIN_USER) {
            // Complete all requirements in all IRS
            for (reduivy__Individual_Requirement__c irq : irsGeneral.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsGeneral.reduivy__Individual_Requirements__r;

            for (reduivy__Individual_Requirement__c irq : irsLocal.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsLocal.reduivy__Individual_Requirements__r;

            for (reduivy__Individual_Requirement__c irq : irsApplication.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsApplication.reduivy__Individual_Requirements__r;
        }

        // Verify indicator is true
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 'Admin indicator should be true!');

        System.runAs(ADMIN_USER) {
            // Set irsGeneral to inactive
            irsGeneral.reduivy__Status__c = IRS_Helper.STATUS_DRAFT;
            update irsGeneral;
        }

        // Verify indicator remains true (inactive IRS ignored, only active irsLocal and irsApplication considered)
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 'Admin indicator should remain true when IRS inactive!');

        System.runAs(ADMIN_USER) {
            // Now make one requirement in irsLocal incomplete
            if (!irsLocal.reduivy__Individual_Requirements__r.isEmpty()) {
                reduivy__Individual_Requirement__c irqToRevert = irsLocal.reduivy__Individual_Requirements__r[0];
                irqToRevert.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_OPEN;
                update irqToRevert;
            }
        }

        // Verify indicator is now false (active irsLocal is incomplete)
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(false, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 'Admin indicator should be false with active IRS incomplete!');

        Test.stopTest();
    }

    /**
     * @description Test deleting IRS updates parent indicators as admin
     */
    @IsTest
    static void testForDelete_IRS_UpdatesParent_AsAdmin() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA()){
            return;
        }
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Program_Application__c ipa = (reduivy__Individual_Program_Application__c)testData.get('ipa');
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');
        reduivy__Individual_Requirement_Set__c irsGeneral = (reduivy__Individual_Requirement_Set__c)testData.get('irsGeneral');
        reduivy__Individual_Requirement_Set__c irsApplication = (reduivy__Individual_Requirement_Set__c)testData.get('irsApplication');
        
        System.runAs(ADMIN_USER) {
            // Complete all requirements in all IRS
            for (reduivy__Individual_Requirement__c irq : irsGeneral.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsGeneral.reduivy__Individual_Requirements__r;

            for (reduivy__Individual_Requirement__c irq : irsLocal.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsLocal.reduivy__Individual_Requirements__r;

            for (reduivy__Individual_Requirement__c irq : irsApplication.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsApplication.reduivy__Individual_Requirements__r;
        }

        // Verify indicator is true
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 'Admin indicator should be true!');

        // Delete one IRS
        System.runAs(ADMIN_USER) {
            delete irsGeneral;
        }

        // Verify indicator remains true (remaining 2 active IRS are complete)
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 'Admin indicator should remain true after IRS deletion!');

        Test.stopTest();
    }

    /**
     * @description Test moving IRS to different parent as admin
     */
    @IsTest
    static void testForUpdate_IRSMovedToNewParent_UpdatesBothParents_AsAdmin() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA()){
            return;
        }
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Program_Application__c ipa = (reduivy__Individual_Program_Application__c)testData.get('ipa');
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');
        reduivy__Individual_Requirement_Set__c irsGeneral = (reduivy__Individual_Requirement_Set__c)testData.get('irsGeneral');
        reduivy__Individual_Requirement_Set__c irsApplication = (reduivy__Individual_Requirement_Set__c)testData.get('irsApplication');
        
        // Create second IPA
        List<Contact> studentContacts = [SELECT Id FROM Contact WHERE reduivy__Contact_Type__c = :CON_Helper.CONTACT_TYPE_STUDENT LIMIT 1];
        List<reduivy__Study_Program__c> spgList = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = :BIS_SPG_PROGRAM_CODE LIMIT 1];
        
        reduivy__Individual_Program_Application__c ipa2 = new reduivy__Individual_Program_Application__c(
            reduivy__Contact__c = studentContacts[0].Id,
            reduivy__Application_Date__c = System.today(),
            reduivy__Application_Status__c = IPA_CREATE_IRS_STATUS,
            reduivy__Study_Program__c = spgList[0].Id
        );
        
        // Set indicators dynamically using put
        ipa2.put('reduivy__Test_Requirements_Complete_Admin__c', false);
        ipa2.put('reduivy__Test_Requirements_Complete_Faculty__c', false);
        ipa2.put('reduivy__Test_Requirements_Complete_Student__c', false);
        
        insert ipa2;

        // Query all IRS for ipa2 (auto-created by factory)
        List<reduivy__Individual_Requirement_Set__c> ipa2IrsList = [
            SELECT Id, reduivy__Study_Requirement_Set__r.reduivy__Sample_Record_Code__c,
                (SELECT Id, reduivy__Review_Status__c, reduivy__Requirement_Visibility__c 
                    FROM reduivy__Individual_Requirements__r
                    WHERE reduivy__Status__c = :IRQ_Helper.STATUS_ACTIVE)
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Program_Application__c = :ipa2.Id
        ];

        System.runAs(ADMIN_USER) {
            // Complete all requirements in IPA1's IRS
            for (reduivy__Individual_Requirement__c irq : irsGeneral.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsGeneral.reduivy__Individual_Requirements__r;

            for (reduivy__Individual_Requirement__c irq : irsLocal.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsLocal.reduivy__Individual_Requirements__r;

            for (reduivy__Individual_Requirement__c irq : irsApplication.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsApplication.reduivy__Individual_Requirements__r;

            // Complete all requirements in IPA2's IRS (except the one we're going to move)
            for (reduivy__Individual_Requirement_Set__c ipa2Irs : ipa2IrsList) {
                if (!ipa2Irs.reduivy__Individual_Requirements__r.isEmpty()) {
                    for (reduivy__Individual_Requirement__c irq : ipa2Irs.reduivy__Individual_Requirements__r) {
                        irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                        irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
                    }
                    update ipa2Irs.reduivy__Individual_Requirements__r;
                }
            }
        }

        // Verify first IPA is complete
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 'First IPA should be complete!');

        // Verify second IPA is complete (all its IRS are complete)
        ipa2 = queryIPA(ipa2.Id);
        System.Assert.areEqual(true, (Boolean) ipa2.get('reduivy__Test_Requirements_Complete_Admin__c'), 'Second IPA should be complete before move!');

        // Move irsGeneral from ipa1 to ipa2
        reduivy__Individual_Requirement_Set__c irsToUpdate = new reduivy__Individual_Requirement_Set__c(Id = irsGeneral.Id, reduivy__Individual_Program_Application__c = ipa2.Id);

        System.runAs(ADMIN_USER) {
            update irsToUpdate;
        }

        // Verify first IPA still complete (irsLocal and irsApplication are still there and complete)
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 'First IPA should still be complete!');

        // Verify second IPA remains complete (all its IRS including the moved one are complete)
        ipa2 = queryIPA(ipa2.Id);
        System.Assert.areEqual(true, (Boolean) ipa2.get('reduivy__Test_Requirements_Complete_Admin__c'), 'Second IPA should still be complete after move!');

        Test.stopTest();
    }

    /**
     * @description Test error handling when completion indicator field doesn't exist on parent object as admin
     */
    @IsTest
    static void testForUpdate_InvalidCompletionField_ThrowsError_AsAdmin() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA()){
            return;
        }
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');

        List<reduivy__Study_Requirement_Set__c> srsListToUpdate = [
            SELECT Id, reduivy__Completion_Indicator_Admin__c, reduivy__Completion_Indicator_Faculty__c, reduivy__Completion_Indicator_Student__c
            FROM reduivy__Study_Requirement_Set__c
        ];

        for(reduivy__Study_Requirement_Set__c srs : srsListToUpdate) {
            srs.reduivy__Completion_Indicator_Admin__c = 'NonExistent_Field__c';
            srs.reduivy__Completion_Indicator_Faculty__c = 'NonExistent_Field__c';
            srs.reduivy__Completion_Indicator_Student__c = 'NonExistent_Field__c';
        }
        
        update srsListToUpdate;

        System.runAs(ADMIN_USER) {
            // Complete all requirements in irsLocal
            for (reduivy__Individual_Requirement__c irq : irsLocal.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }

            try {
                update irsLocal.reduivy__Individual_Requirements__r;
                System.Assert.fail('Expected Exception for non-existent field');
            } catch (Exception exp) {
                String expectedError = String.format(Label.Invalid_Object_Field_Error, 
                    new List<String>{'NonExistent_Field__c', IPA_Helper.getApiName()});
                System.Assert.isTrue(exp.getMessage().contains(expectedError), 
                    'Expected error message about field not found. Actual: ' + exp.getMessage());
            }
        }

        Test.stopTest();
    }

    /**
     * @description Test error handling when completion indicator field is not a checkbox/boolean as admin
     */
    @IsTest
    static void testForUpdate_NonBooleanCompletionField_ThrowsError_AsAdmin() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA()){
            return;
        }
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');

        List<reduivy__Study_Requirement_Set__c> srsListToUpdate = [
            SELECT Id, reduivy__Completion_Indicator_Admin__c, reduivy__Completion_Indicator_Faculty__c, reduivy__Completion_Indicator_Student__c
            FROM reduivy__Study_Requirement_Set__c
        ];

        // Update SRS with a text field instead of checkbox
        for(reduivy__Study_Requirement_Set__c srs : srsListToUpdate) {
            srs.reduivy__Completion_Indicator_Admin__c = 'Name';
            srs.reduivy__Completion_Indicator_Faculty__c = 'Name';
            srs.reduivy__Completion_Indicator_Student__c = 'Name';
        }
        
        update srsListToUpdate;
        
        System.runAs(ADMIN_USER) {
            // Complete all requirements in irsLocal
            for (reduivy__Individual_Requirement__c irq : irsLocal.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }

            try {
                update irsLocal.reduivy__Individual_Requirements__r;
                System.Assert.fail('Expected Exception for non-boolean field');
            } catch (Exception exp) {
                String expectedError = String.format(Label.Field_Not_Boolean, 
                    new List<String>{'Name', IPA_Helper.getApiName()});
                System.Assert.isTrue(exp.getMessage().contains(expectedError), 
                    'Expected error message about field not being boolean. Actual: ' + exp.getMessage());
            }
        }

        Test.stopTest();
    }

    /**
     * @description Test with IRS that has no Study Requirement Set reference as admin
     */
    @IsTest
    static void testForUpdate_IRSWithNoSRS_NoUpdate_AsAdmin() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA()){
            return;
        }
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Program_Application__c ipa = (reduivy__Individual_Program_Application__c)testData.get('ipa');
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');
        
        // Clear Study Requirement Set reference
        irsLocal.reduivy__Study_Requirement_Set__c = null;
        
        System.runAs(ADMIN_USER) {
            update irsLocal;
        }

        // Verify no errors and indicators remain unchanged
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(false, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 
            'Indicator should remain false when IRS has no SRS reference');

        Test.stopTest();
    }

    /**
     * @description Test with IRS that has zero requirements as admin
     */
    @IsTest
    static void testForUpdate_IRSWithZeroRequirements_IgnoredInCalculation_AsAdmin() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA()){
            return;
        }
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Program_Application__c ipa = (reduivy__Individual_Program_Application__c)testData.get('ipa');
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');
        reduivy__Individual_Requirement_Set__c irsGeneral = (reduivy__Individual_Requirement_Set__c)testData.get('irsGeneral');
        reduivy__Individual_Requirement_Set__c irsApplication = (reduivy__Individual_Requirement_Set__c)testData.get('irsApplication');
        
        // Delete all requirements from irsLocal to make it have zero requirements
        if (!irsLocal.reduivy__Individual_Requirements__r.isEmpty()) {
            delete irsLocal.reduivy__Individual_Requirements__r;
        }

        System.runAs(ADMIN_USER) {
            // Complete all requirements in other IRS
            for (reduivy__Individual_Requirement__c irq : irsGeneral.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsGeneral.reduivy__Individual_Requirements__r;

            for (reduivy__Individual_Requirement__c irq : irsApplication.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsApplication.reduivy__Individual_Requirements__r;
        }

        // Verify indicator is true (IRS with zero requirements should be ignored)
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 
            'Indicator should be true when IRS with zero requirements is ignored');

        Test.stopTest();
    }

    /**
     * @description Test bulk update with multiple IRS records as admin
     */
    @IsTest
    static void testForUpdate_BulkUpdate_AllIndicatorsUpdated_AsAdmin() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA()){
            return;
        }
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Program_Application__c ipa = (reduivy__Individual_Program_Application__c)testData.get('ipa');
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');
        reduivy__Individual_Requirement_Set__c irsGeneral = (reduivy__Individual_Requirement_Set__c)testData.get('irsGeneral');
        reduivy__Individual_Requirement_Set__c irsApplication = (reduivy__Individual_Requirement_Set__c)testData.get('irsApplication');
        
        // Prepare bulk update of all IRQ across all IRS
        List<reduivy__Individual_Requirement__c> allIrqs = new List<reduivy__Individual_Requirement__c>();
        
        for (reduivy__Individual_Requirement__c irq : irsGeneral.reduivy__Individual_Requirements__r) {
            irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
            irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            allIrqs.add(irq);
        }
        
        for (reduivy__Individual_Requirement__c irq : irsLocal.reduivy__Individual_Requirements__r) {
            irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
            irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            allIrqs.add(irq);
        }
        
        for (reduivy__Individual_Requirement__c irq : irsApplication.reduivy__Individual_Requirements__r) {
            irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
            irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            allIrqs.add(irq);
        }

        System.runAs(ADMIN_USER) {
            update allIrqs;
        }

        // Verify indicator is updated correctly
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 
            'Admin indicator should be true after bulk update');

        Test.stopTest();
    }

    /**
     * @description Test with mixed active and inactive IRS - verify only active ones affect calculation as admin
     */
    @IsTest
    static void testForUpdate_MixedActiveInactive_OnlyActiveConsidered_AsAdmin() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA()){
            return;
        }
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Program_Application__c ipa = (reduivy__Individual_Program_Application__c)testData.get('ipa');
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');
        reduivy__Individual_Requirement_Set__c irsGeneral = (reduivy__Individual_Requirement_Set__c)testData.get('irsGeneral');
        reduivy__Individual_Requirement_Set__c irsApplication = (reduivy__Individual_Requirement_Set__c)testData.get('irsApplication');
        
        // Set irsGeneral and irsApplication to inactive
        irsGeneral.reduivy__Status__c = IRS_Helper.STATUS_DRAFT;
        irsApplication.reduivy__Status__c = IRS_Helper.STATUS_DRAFT;
        
        System.runAs(ADMIN_USER) {
            List<reduivy__Individual_Requirement_Set__c> irsToUpdate = new List<reduivy__Individual_Requirement_Set__c>{
                irsGeneral, irsApplication
            };
            update irsToUpdate;

            // Complete all requirements in irsLocal (only active IRS)
            for (reduivy__Individual_Requirement__c irq : irsLocal.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsLocal.reduivy__Individual_Requirements__r;
        }

        // Verify indicator is true (only active irsLocal is considered and it's complete)
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 
            'Indicator should be true when only active IRS is complete');

        Test.stopTest();
    }

    /**
     * @description Test changing IRS status from active to inactive as admin
     */
    @IsTest
    static void testForUpdate_ChangeStatusToInactive_RecalculatesIndicator_AsAdmin() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA()){
            return;
        }
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Program_Application__c ipa = (reduivy__Individual_Program_Application__c)testData.get('ipa');
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');
        reduivy__Individual_Requirement_Set__c irsGeneral = (reduivy__Individual_Requirement_Set__c)testData.get('irsGeneral');
        reduivy__Individual_Requirement_Set__c irsApplication = (reduivy__Individual_Requirement_Set__c)testData.get('irsApplication');
        
        System.runAs(ADMIN_USER) {
            // Complete requirements in irsGeneral and irsApplication only
            for (reduivy__Individual_Requirement__c irq : irsGeneral.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsGeneral.reduivy__Individual_Requirements__r;

            for (reduivy__Individual_Requirement__c irq : irsApplication.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsApplication.reduivy__Individual_Requirements__r;
        }

        // Leave irsLocal incomplete
        // Verify indicator is false
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(false, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 
            'Indicator should be false with incomplete irsLocal');

        // Change irsLocal status to inactive
        irsLocal.reduivy__Status__c = IRS_Helper.STATUS_DRAFT;
        System.runAs(ADMIN_USER) {
            update irsLocal;
        }

        // Verify indicator is now true (inactive IRS ignored, only active ones are complete)
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 
            'Indicator should be true when incomplete IRS becomes inactive');

        Test.stopTest();
    }

    /**
     * @description Test changing IRS status from inactive to active as admin
     */
    @IsTest
    static void testForUpdate_ChangeStatusToActive_RecalculatesIndicator_AsAdmin() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA()){
            return;
        }
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Program_Application__c ipa = (reduivy__Individual_Program_Application__c)testData.get('ipa');
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');
        reduivy__Individual_Requirement_Set__c irsGeneral = (reduivy__Individual_Requirement_Set__c)testData.get('irsGeneral');
        reduivy__Individual_Requirement_Set__c irsApplication = (reduivy__Individual_Requirement_Set__c)testData.get('irsApplication');
        
        // Set irsLocal to inactive initially
        irsLocal.reduivy__Status__c = IRS_Helper.STATUS_DRAFT;
        System.runAs(ADMIN_USER) {
            update irsLocal;

            // Complete all requirements in other IRS
            for (reduivy__Individual_Requirement__c irq : irsGeneral.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsGeneral.reduivy__Individual_Requirements__r;

            for (reduivy__Individual_Requirement__c irq : irsApplication.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsApplication.reduivy__Individual_Requirements__r;
        }

        // Verify indicator is true (inactive IRS ignored)
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 
            'Indicator should be true with inactive IRS');

        // Activate irsLocal (which has incomplete requirements)
        irsLocal.reduivy__Status__c = IRS_Helper.STATUS_ACTIVE;
        System.runAs(ADMIN_USER) {
            update irsLocal;
        }

        // Verify indicator is now false (newly activated IRS is incomplete)
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(false, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 
            'Indicator should be false when incomplete IRS becomes active');

        Test.stopTest();
    }

    /**
     * @description Test multiple parent objects - Contact and IPA with same indicators as admin
     */
    @IsTest
    static void testForUpdate_MultipleParentObjects_BothUpdated_AsAdmin() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA() || !CON_Helper.canRunEvaluationTestForRequirementIndicatorInContact()){
            return;
        }

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Program_Application__c ipa = (reduivy__Individual_Program_Application__c)testData.get('ipa');
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');
        reduivy__Individual_Requirement_Set__c irsGeneral = (reduivy__Individual_Requirement_Set__c)testData.get('irsGeneral');
        reduivy__Individual_Requirement_Set__c irsApplication = (reduivy__Individual_Requirement_Set__c)testData.get('irsApplication');
        
        // Get the contact associated with the IPA
        Contact studentContact = [
            SELECT Id, 
                   (SELECT Id FROM reduivy__Individual_Requirement_Sets__r)
            FROM Contact
            WHERE Id = :ipa.reduivy__Contact__c
            LIMIT 1
        ];
        
        // Verify initial state - Contact indicators should be false using dynamic field access
        studentContact = queryContact(studentContact.Id);
        System.Assert.areEqual(false, (Boolean) studentContact.get('reduivy__Test_Requirements_Complete_Admin__c'), 
            'Contact Admin indicator should be false initially!');
        System.Assert.areEqual(false, (Boolean) studentContact.get('reduivy__Test_Requirements_Complete_Faculty__c'), 
            'Contact Faculty indicator should be false initially!');
        System.Assert.areEqual(false, (Boolean) studentContact.get('reduivy__Test_Requirements_Complete_Student__c'), 
            'Contact Student indicator should be false initially!');
        
        // Update some SRS to point to Contact instead of IPA
        List<reduivy__Study_Requirement_Set__c> srsListToUpdate = [
            SELECT Id, reduivy__Object__c, reduivy__Sample_Record_Code__c,
                reduivy__Completion_Indicator_Admin__c,
                reduivy__Completion_Indicator_Faculty__c,
                reduivy__Completion_Indicator_Student__c
            FROM reduivy__Study_Requirement_Set__c
            WHERE reduivy__Sample_Record_Code__c IN (:SRS_LOCAL, :SRS_GENERAL)
        ];
        
        for (reduivy__Study_Requirement_Set__c srs : srsListToUpdate) {
            // Change object to Contact
            srs.reduivy__Object__c = CON_Helper.getApiName();
            // Keep the same indicator fields
            srs.reduivy__Completion_Indicator_Admin__c = 'reduivy__Test_Requirements_Complete_Admin__c';
            srs.reduivy__Completion_Indicator_Faculty__c = 'reduivy__Test_Requirements_Complete_Faculty__c';
            srs.reduivy__Completion_Indicator_Student__c = 'reduivy__Test_Requirements_Complete_Student__c';
        }
        
        System.runAs(ADMIN_USER) {
            update srsListToUpdate;
        }
        
        // Update IRS to point to Contact for Local and General
        irsLocal.reduivy__Contact__c = studentContact.Id;
        irsGeneral.reduivy__Contact__c = studentContact.Id;
        
        List<reduivy__Individual_Requirement_Set__c> irsToUpdate = new List<reduivy__Individual_Requirement_Set__c>{
            irsLocal, irsGeneral
        };
        
        System.runAs(ADMIN_USER) {
            update irsToUpdate;
        }
        
        // Now we have:
        // - irsLocal -> Contact (Admin visibility)
        // - irsGeneral -> Contact (Admin visibility)
        // - irsApplication -> IPA (Admin visibility)
        
        System.runAs(ADMIN_USER) {
            // Complete all requirements in irsLocal (Contact parent - Admin visibility)
            for (reduivy__Individual_Requirement__c irq : irsLocal.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsLocal.reduivy__Individual_Requirements__r;
        }
        
        // Verify Contact indicator is still false (irsGeneral not complete yet)
        studentContact = queryContact(studentContact.Id);
        System.Assert.areEqual(false, (Boolean) studentContact.get('reduivy__Test_Requirements_Complete_Admin__c'), 
            'Contact Admin indicator should be false with one IRS incomplete!');
        
        System.runAs(ADMIN_USER) {
            // Complete all requirements in irsGeneral (Contact parent - Admin visibility)
            for (reduivy__Individual_Requirement__c irq : irsGeneral.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsGeneral.reduivy__Individual_Requirements__r;
        }
        
        // Verify Contact indicator is now true (both IRS complete)
        studentContact = queryContact(studentContact.Id);
        System.Assert.areEqual(true, (Boolean) studentContact.get('reduivy__Test_Requirements_Complete_Admin__c'), 
            'Contact Admin indicator should be true with all Contact IRS complete!');
        
        // Verify IPA indicator is still false (irsApplication not complete yet)
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(false, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 
            'IPA Admin indicator should be false with IPA IRS incomplete!');
        
        System.runAs(ADMIN_USER) {
            // Complete all requirements in irsApplication (IPA parent - Admin visibility)
            for (reduivy__Individual_Requirement__c irq : irsApplication.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsApplication.reduivy__Individual_Requirements__r;
        }
        
        // Verify IPA indicator is now true
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 
            'IPA Admin indicator should be true with all IPA IRS complete!');
        
        // Verify Contact indicator remains true
        studentContact = queryContact(studentContact.Id);
        System.Assert.areEqual(true, (Boolean) studentContact.get('reduivy__Test_Requirements_Complete_Admin__c'), 
            'Contact Admin indicator should remain true!');
        
        Test.stopTest();
    }

    /**
     * @description Test multiple parent objects with mixed visibility as admin
     */
    @IsTest
    static void testForUpdate_MultipleParentObjects_MixedVisibility_AsAdmin() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA() || !CON_Helper.canRunEvaluationTestForRequirementIndicatorInContact()){
            return;
        }

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Program_Application__c ipa = (reduivy__Individual_Program_Application__c)testData.get('ipa');
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');
        reduivy__Individual_Requirement_Set__c irsGeneral = (reduivy__Individual_Requirement_Set__c)testData.get('irsGeneral');
        reduivy__Individual_Requirement_Set__c irsApplication = (reduivy__Individual_Requirement_Set__c)testData.get('irsApplication');
        
        // Get the contact associated with the IPA
        Contact studentContact = [
            SELECT Id
            FROM Contact
            WHERE Id = :ipa.reduivy__Contact__c
            LIMIT 1
        ];
        
        // Update SRS to point to different objects
        List<reduivy__Study_Requirement_Set__c> srsListToUpdate = [
            SELECT Id, reduivy__Object__c, reduivy__Sample_Record_Code__c,
                reduivy__Completion_Indicator_Admin__c,
                reduivy__Completion_Indicator_Faculty__c,
                reduivy__Completion_Indicator_Student__c
            FROM reduivy__Study_Requirement_Set__c
            WHERE reduivy__Sample_Record_Code__c IN (:SRS_LOCAL)
        ];
        
        for (reduivy__Study_Requirement_Set__c srs : srsListToUpdate) {
            // Change object to Contact
            srs.reduivy__Object__c = CON_Helper.getApiName();
            srs.reduivy__Completion_Indicator_Admin__c = 'reduivy__Test_Requirements_Complete_Admin__c';
            srs.reduivy__Completion_Indicator_Faculty__c = 'reduivy__Test_Requirements_Complete_Faculty__c';
            srs.reduivy__Completion_Indicator_Student__c = 'reduivy__Test_Requirements_Complete_Student__c';
        }
        
        System.runAs(ADMIN_USER) {
            update srsListToUpdate;
        }
        
        // Update IRS to point to Contact for Local and General
        irsLocal.reduivy__Contact__c = studentContact.Id;
        irsGeneral.reduivy__Contact__c = studentContact.Id;
        
        List<reduivy__Individual_Requirement_Set__c> irsToUpdateParent = new List<reduivy__Individual_Requirement_Set__c>{
            irsLocal, irsGeneral
        };
        
        System.runAs(ADMIN_USER) {
            update irsToUpdateParent;
        }
        
        System.runAs(ADMIN_USER) {
            // Set Contact IRS (irsLocal, irsGeneral) to Faculty visibility and complete them
            for (reduivy__Individual_Requirement__c irq : irsLocal.reduivy__Individual_Requirements__r) {
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_FACULTY;
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
            }
            update irsLocal.reduivy__Individual_Requirements__r;
            
            for (reduivy__Individual_Requirement__c irq : irsGeneral.reduivy__Individual_Requirements__r) {
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_FACULTY;
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
            }
            update irsGeneral.reduivy__Individual_Requirements__r;
        
            // Set IPA IRS (irsApplication) to Student visibility and complete them
            for (reduivy__Individual_Requirement__c irq : irsApplication.reduivy__Individual_Requirements__r) {
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT;
                irq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
            }
            update irsApplication.reduivy__Individual_Requirements__r;
        }
        
        // Verify Contact Faculty indicator is true
        studentContact = queryContact(studentContact.Id);
        System.Assert.areEqual(true, (Boolean) studentContact.get('reduivy__Test_Requirements_Complete_Faculty__c'), 
            'Contact Faculty indicator should be true!');
        System.Assert.areEqual(true, (Boolean) studentContact.get('reduivy__Test_Requirements_Complete_Admin__c'), 
            'Contact Admin indicator should be true!');
        
        // Verify IPA Student indicator is true
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Student__c'), 
            'IPA Student indicator should be true!');
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 
            'IPA Admin indicator should be true!');
        
        Test.stopTest();
    }

    /**
     * @description Test AfterInsert - IRS created with completed requirements should update parent as admin
     */
    @IsTest
    static void testForInsert_NewIRSWithCompletedRequirements_UpdatesParent_AsAdmin() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA()){
            return;
        }

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Program_Application__c ipa = (reduivy__Individual_Program_Application__c)testData.get('ipa');
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');
        reduivy__Individual_Requirement_Set__c irsGeneral = (reduivy__Individual_Requirement_Set__c)testData.get('irsGeneral');
        reduivy__Individual_Requirement_Set__c irsApplication = (reduivy__Individual_Requirement_Set__c)testData.get('irsApplication');
        
        System.runAs(ADMIN_USER) {
            // Complete all existing IRS requirements
            for (reduivy__Individual_Requirement__c irq : irsGeneral.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsGeneral.reduivy__Individual_Requirements__r;

            for (reduivy__Individual_Requirement__c irq : irsLocal.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsLocal.reduivy__Individual_Requirements__r;

            for (reduivy__Individual_Requirement__c irq : irsApplication.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsApplication.reduivy__Individual_Requirements__r;
        }

        // Verify parent is complete
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 
            'IPA should be complete before new IRS!');

        // Create a new IRS manually (simulating AfterInsert)
        // Get SRS
        List<reduivy__Study_Requirement_Set__c> srsList = [
            SELECT Id, reduivy__Object__c
            FROM reduivy__Study_Requirement_Set__c
            WHERE reduivy__Sample_Record_Code__c = :SRS_LOCAL
            LIMIT 1
        ];

        // Create new IRS
        reduivy__Individual_Requirement_Set__c newIrs = new reduivy__Individual_Requirement_Set__c(
            reduivy__Study_Requirement_Set__c = srsList[0].Id,
            reduivy__Individual_Program_Application__c = ipa.Id,
            reduivy__Status__c = IRS_Helper.STATUS_ACTIVE,
            reduivy__Total_Requirement__c = 1,
            reduivy__Total_Reviewed__c = 0, // Incomplete
            reduivy__Total_Requirement_Faculty__c = 0,
            reduivy__Total_Requirement_Student__c = 0
        );

        System.runAs(ADMIN_USER) {
            insert newIrs;
        }

        // Verify parent indicator is now false (new incomplete IRS added)
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(false, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 
            'IPA should be incomplete after new incomplete IRS inserted!');

        Test.stopTest();
    }

    /**
     * @description Test AfterUndelete - Undeleting incomplete IRS should update parent to false as admin
     */
    @IsTest
    static void testForUndelete_IncompleteIRS_UpdatesParentToFalse_AsAdmin() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA()){
            return;
        }

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Program_Application__c ipa = (reduivy__Individual_Program_Application__c)testData.get('ipa');
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');
        reduivy__Individual_Requirement_Set__c irsGeneral = (reduivy__Individual_Requirement_Set__c)testData.get('irsGeneral');
        reduivy__Individual_Requirement_Set__c irsApplication = (reduivy__Individual_Requirement_Set__c)testData.get('irsApplication');
        
        System.runAs(ADMIN_USER) {
            // Complete requirements in irsGeneral and irsApplication only
            for (reduivy__Individual_Requirement__c irq : irsGeneral.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsGeneral.reduivy__Individual_Requirements__r;

            for (reduivy__Individual_Requirement__c irq : irsApplication.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsApplication.reduivy__Individual_Requirements__r;
        }

        // Leave irsLocal incomplete
        // Verify parent indicator is false
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(false, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'),
            'IPA should be incomplete before the incomplete IRS is deleted!');
        
        // Mute the rollup trigger so the total numbers will not change after the IRS and IRQ are deleted. This is to cover the undelete method
        REDU_TriggerController.muteTriggers(new Set<String>{'IRQ_IndividualRequirementSetRollup_EXE'});

        // Delete irsLocal
        System.runAs(ADMIN_USER) {
            delete irsLocal;
        }

        // Verify parent indicator is true (incomplete IRS deleted)
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 
            'IPA should be complete after incomplete IRS deleted!');

        // Undelete irsLocal (incomplete)
        System.runAs(ADMIN_USER) {
            undelete irsLocal;
        }

        // Verify parent indicator is now false (incomplete IRS undeleted)
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(false, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 
            'IPA should be incomplete after incomplete IRS undeleted!');

        Test.stopTest();
    }

    /**
     * @description Test error handling when more than 5 different parent objects are being processed as admin
     */
    @IsTest
    static void testForUpdate_MoreThan5ParentObjects_ThrowsError_AsAdmin() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA()){
            return;
        }
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Program_Application__c ipa = (reduivy__Individual_Program_Application__c)testData.get('ipa');
        
        List<reduivy__Study_Requirement_Set__c> srsListToCreate = new List<reduivy__Study_Requirement_Set__c>();
        
        // Create 6 SRS pointing to different objects
        List<String> parentObjects = new List<String>{
            'Account',
            'Contact', 
            'Opportunity',
            'Lead',
            'Case',
            'Campaign'
        };
        
        for (Integer i = 0; i < 6; i++) {
            reduivy__Study_Requirement_Set__c srs = new reduivy__Study_Requirement_Set__c(
                Name = 'Test SRS ' + i,
                reduivy__Object__c = parentObjects[i],
                reduivy__Sample_Record_Code__c = 'TEST_SRS_' + i,
                reduivy__Completion_Indicator_Admin__c = 'reduivy__Test_Requirements_Complete_Admin__c',
                reduivy__Completion_Indicator_Faculty__c = 'reduivy__Test_Requirements_Complete_Faculty__c',
                reduivy__Completion_Indicator_Student__c = 'reduivy__Test_Requirements_Complete_Student__c',
                reduivy__Status__c = SRS_Helper.STATUS_ACTIVE,
                reduivy__Requirement_Generation_Mode__c = IRS_Helper.REQUIREMENT_GENERATION_MODE_MANUAL
            );
            srsListToCreate.add(srs);
        }
        
        insert srsListToCreate;
        
        // Create 6 IRS records, each pointing to a different SRS (thus 6 different parent objects)
        List<reduivy__Individual_Requirement_Set__c> irsList = new List<reduivy__Individual_Requirement_Set__c>();
        
        for (Integer i = 0; i < 6; i++) {
            reduivy__Individual_Requirement_Set__c irs = new reduivy__Individual_Requirement_Set__c(
                reduivy__Study_Requirement_Set__c = srsListToCreate[i].Id,
                reduivy__Individual_Program_Application__c = ipa.Id,
                reduivy__Status__c = IRS_Helper.STATUS_ACTIVE,
                reduivy__Total_Requirement__c = 1,
                reduivy__Total_Reviewed__c = 0,
                reduivy__Total_Requirement_Faculty__c = 1,
                reduivy__Total_Requirement_Student__c = 1
            );
            irsList.add(irs);
        }
        
        System.runAs(ADMIN_USER) {
            try {
                insert irsList;
                System.Assert.fail('Expected Exception for processing more than 5 parent objects');
            } catch (Exception exp) {
                String expectedError = String.format(Label.Too_Many_Parent_Objects_In_Transaction,
                            new List<String>{SRS_Helper.getObjectLabel(), String.join(parentObjects, ',')});
                System.Assert.isTrue(exp.getMessage().contains(expectedError), 
                    'Expected error message about too many parent objects. Actual: ' + exp.getMessage());
            }
        }

        Test.stopTest();
    }

    /**
     * @description Test all requirements complete in all IRS - should set indicators to true as faculty
     */
    @IsTest
    static void testForUpdate_AllIRSComplete_AllIndicatorsTrue_AsFaculty() {

        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA()){
            return;
        }

        User FACULTY_USER = testFactory.getReduFacultyUser();
        transferIRQOwnership(FACULTY_USER.Id);

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Program_Application__c ipa = (reduivy__Individual_Program_Application__c)testData.get('ipa');
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');
        reduivy__Individual_Requirement_Set__c irsGeneral = (reduivy__Individual_Requirement_Set__c)testData.get('irsGeneral');
        reduivy__Individual_Requirement_Set__c irsApplication = (reduivy__Individual_Requirement_Set__c)testData.get('irsApplication');

        // Verify initial state - all indicators should be false
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(false, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 'Admin indicator should be false initially!');
        System.Assert.areEqual(false, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Faculty__c'), 'Faculty indicator should be false initially!');
        System.Assert.areEqual(false, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Student__c'), 'Student indicator should be false initially!');

        System.runAs(FACULTY_USER) {
            // Complete all requirements in irsGeneral (Admin visibility)
            for (reduivy__Individual_Requirement__c irq : irsGeneral.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsGeneral.reduivy__Individual_Requirements__r;
        }

        // Verify admin indicator is still false (irsLocal and irsApplication not complete yet)
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(false, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 'Admin indicator should be false with two IRS incomplete!');

        System.runAs(FACULTY_USER) {
            // Complete all requirements in irsLocal (Admin visibility)
            for (reduivy__Individual_Requirement__c irq : irsLocal.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsLocal.reduivy__Individual_Requirements__r;
        }

        // Verify admin indicator is still false (irsApplication not complete yet)
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(false, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 'Admin indicator should be false with one IRS incomplete!');

        System.runAs(FACULTY_USER) {
            // Complete all requirements in irsApplication (Admin visibility)
            for (reduivy__Individual_Requirement__c irq : irsApplication.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsApplication.reduivy__Individual_Requirements__r;
        }
        
        // Verify admin indicator is now true (all 3 IRS complete)
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 'Admin indicator should be true with all IRS complete!');

        Test.stopTest();
    }

    /**
     * @description Test one IRS incomplete - should keep indicator false  as faculty
     */
    @IsTest
    static void testForUpdate_OneIRSIncomplete_IndicatorFalse_AsFaculty() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA()){
            return;
        }

        User FACULTY_USER = testFactory.getReduFacultyUser();
        transferIRQOwnership(FACULTY_USER.Id);

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Program_Application__c ipa = (reduivy__Individual_Program_Application__c)testData.get('ipa');
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');
        reduivy__Individual_Requirement_Set__c irsGeneral = (reduivy__Individual_Requirement_Set__c)testData.get('irsGeneral');
        reduivy__Individual_Requirement_Set__c irsApplication = (reduivy__Individual_Requirement_Set__c)testData.get('irsApplication');
        
        System.runAs(FACULTY_USER) {
            // Complete all requirements in irsGeneral
            for (reduivy__Individual_Requirement__c irq : irsGeneral.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsGeneral.reduivy__Individual_Requirements__r;

            // Complete all requirements in irsApplication
            for (reduivy__Individual_Requirement__c irq : irsApplication.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsApplication.reduivy__Individual_Requirements__r;

            // Leave irsLocal incomplete (complete all except the last one if multiple requirements exist)
            if (irsLocal.reduivy__Individual_Requirements__r.size() > 1) {
                List<reduivy__Individual_Requirement__c> localIrqsToComplete = new List<reduivy__Individual_Requirement__c>();
                for (Integer i = 0; i < irsLocal.reduivy__Individual_Requirements__r.size() - 1; i++) {
                    reduivy__Individual_Requirement__c irq = irsLocal.reduivy__Individual_Requirements__r[i];
                    irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                    irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
                    localIrqsToComplete.add(irq);
                }
                if (!localIrqsToComplete.isEmpty()) {
                    update localIrqsToComplete;
                }
            }
        }

        // Verify admin indicator is false (one IRS incomplete)
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(false, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 'Admin indicator should be false when any IRS incomplete!');

        Test.stopTest();
    }

    /**
     * @description Test Faculty visibility - complete all Faculty visible requirements as faculty
     */
    @IsTest
    static void testForUpdate_FacultyVisibility_AllComplete_IndicatorTrue_AsFaculty() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA()){
            return;
        }

        User FACULTY_USER = testFactory.getReduFacultyUser();
        transferIRQOwnership(FACULTY_USER.Id);

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Program_Application__c ipa = (reduivy__Individual_Program_Application__c)testData.get('ipa');
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');
        reduivy__Individual_Requirement_Set__c irsGeneral = (reduivy__Individual_Requirement_Set__c)testData.get('irsGeneral');
        reduivy__Individual_Requirement_Set__c irsApplication = (reduivy__Individual_Requirement_Set__c)testData.get('irsApplication');
        
        System.runAs(FACULTY_USER) {
            // Set all requirements to Faculty visibility and complete them
            for (reduivy__Individual_Requirement__c irq : irsGeneral.reduivy__Individual_Requirements__r) {
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_FACULTY;
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
            }
            update irsGeneral.reduivy__Individual_Requirements__r;

            for (reduivy__Individual_Requirement__c irq : irsLocal.reduivy__Individual_Requirements__r) {
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_FACULTY;
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
            }
            update irsLocal.reduivy__Individual_Requirements__r;

            for (reduivy__Individual_Requirement__c irq : irsApplication.reduivy__Individual_Requirements__r) {
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_FACULTY;
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
            }
            update irsApplication.reduivy__Individual_Requirements__r;
        }

        // Verify Faculty indicator is true
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Faculty__c'), 'Faculty indicator should be true with all Faculty requirements complete!');

        Test.stopTest();
    }

    /**
     * @description Test Student visibility - complete all Student visible requirements as faculty
     */
    @IsTest
    static void testForUpdate_StudentVisibility_AllComplete_IndicatorTrue_AsFaculty() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA()){
            return;
        }
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        transferIRQOwnership(FACULTY_USER.Id);

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Program_Application__c ipa = (reduivy__Individual_Program_Application__c)testData.get('ipa');
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');
        reduivy__Individual_Requirement_Set__c irsGeneral = (reduivy__Individual_Requirement_Set__c)testData.get('irsGeneral');
        reduivy__Individual_Requirement_Set__c irsApplication = (reduivy__Individual_Requirement_Set__c)testData.get('irsApplication');
        
        System.runAs(FACULTY_USER) {
            // Set all requirements to Student visibility and submit them
            for (reduivy__Individual_Requirement__c irq : irsGeneral.reduivy__Individual_Requirements__r) {
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT;
                irq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
            }
            update irsGeneral.reduivy__Individual_Requirements__r;

            for (reduivy__Individual_Requirement__c irq : irsLocal.reduivy__Individual_Requirements__r) {
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT;
                irq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
            }
            update irsLocal.reduivy__Individual_Requirements__r;

            for (reduivy__Individual_Requirement__c irq : irsApplication.reduivy__Individual_Requirements__r) {
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT;
                irq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
            }
            update irsApplication.reduivy__Individual_Requirements__r;
        }

        // Verify Student indicator is true
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Student__c'), 'Student indicator should be true with all Student requirements submitted!');

        Test.stopTest();
    }

    /**
     * @description Test mixed visibility - verify each indicator tracks its own requirements as faculty
     */
    @IsTest
    static void testForUpdate_MixedVisibility_IndependentIndicators_AsFaculty() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA()){
            return;
        }
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        transferIRQOwnership(FACULTY_USER.Id);

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Program_Application__c ipa = (reduivy__Individual_Program_Application__c)testData.get('ipa');
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');
        reduivy__Individual_Requirement_Set__c irsGeneral = (reduivy__Individual_Requirement_Set__c)testData.get('irsGeneral');
        reduivy__Individual_Requirement_Set__c irsApplication = (reduivy__Individual_Requirement_Set__c)testData.get('irsApplication');
        
        System.runAs(FACULTY_USER) {
            // irsGeneral: Set requirements to different visibilities and complete them
            List<reduivy__Individual_Requirement__c> generalIrqs = irsGeneral.reduivy__Individual_Requirements__r;
            if (generalIrqs.size() > 0) {
                // Set first requirement to Admin
                generalIrqs[0].reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
                generalIrqs[0].reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                
                // Set remaining requirements to Faculty
                for (Integer i = 1; i < generalIrqs.size(); i++) {
                    generalIrqs[i].reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_FACULTY;
                    generalIrqs[i].reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                }
            }
            update generalIrqs;

            // irsLocal: Set requirements to different visibilities
            List<reduivy__Individual_Requirement__c> localIrqs = irsLocal.reduivy__Individual_Requirements__r;
            if (localIrqs.size() > 0) {
                // Set first requirement to Admin
                localIrqs[0].reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
                localIrqs[0].reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                
                // Set remaining requirements to Student
                for (Integer i = 1; i < localIrqs.size(); i++) {
                    localIrqs[i].reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT;
                    localIrqs[i].reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
                    localIrqs[i].reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                }
            }
            update localIrqs;

            // irsApplication: Set all to Admin and complete them
            for (reduivy__Individual_Requirement__c irq : irsApplication.reduivy__Individual_Requirements__r) {
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
            }
            update irsApplication.reduivy__Individual_Requirements__r;
        }

        // Verify indicators
        ipa = queryIPA(ipa.Id);
        // Admin: All 3 IRS have Admin requirements complete
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 'Admin indicator should be true!');
        // Faculty: Only irsGeneral has Faculty requirements complete, others have none
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Faculty__c'), 'Faculty indicator should be true!');
        // Student: Only irsLocal has Student requirements complete, others have none
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Student__c'), 'Student indicator should be true!');

        Test.stopTest();
    }

    /**
     * @description Test changing requirement from complete to incomplete as faculty
     */
    @IsTest
    static void testForUpdate_RevertCompletion_IndicatorsFalse_AsFaculty() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA()){
            return;
        }
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        transferIRQOwnership(FACULTY_USER.Id);

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Program_Application__c ipa = (reduivy__Individual_Program_Application__c)testData.get('ipa');
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');
        reduivy__Individual_Requirement_Set__c irsGeneral = (reduivy__Individual_Requirement_Set__c)testData.get('irsGeneral');
        reduivy__Individual_Requirement_Set__c irsApplication = (reduivy__Individual_Requirement_Set__c)testData.get('irsApplication');
        
        System.runAs(FACULTY_USER) {
            // Complete all requirements in all IRS
            for (reduivy__Individual_Requirement__c irq : irsGeneral.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsGeneral.reduivy__Individual_Requirements__r;

            for (reduivy__Individual_Requirement__c irq : irsLocal.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsLocal.reduivy__Individual_Requirements__r;

            for (reduivy__Individual_Requirement__c irq : irsApplication.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsApplication.reduivy__Individual_Requirements__r;
        }

        // Verify indicator is true
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 'Admin indicator should be true!');

        System.runAs(FACULTY_USER) {
            // Revert any one requirement to incomplete
            if (!irsLocal.reduivy__Individual_Requirements__r.isEmpty()) {
                reduivy__Individual_Requirement__c irqToRevert = irsLocal.reduivy__Individual_Requirements__r[0];
                irqToRevert.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_OPEN;
                update irqToRevert;
            }
        }

        // Verify indicator is now false
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(false, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 'Admin indicator should be false after reverting!');

        Test.stopTest();
    }

    /**
     * @description Test error handling when completion indicator field doesn't exist on parent object as faculty
     */
    @IsTest
    static void testForUpdate_InvalidCompletionField_ThrowsError_AsFaculty() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA()){
            return;
        }
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        transferIRQOwnership(FACULTY_USER.Id);

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');

        List<reduivy__Study_Requirement_Set__c> srsListToUpdate = [
            SELECT Id, reduivy__Completion_Indicator_Admin__c, reduivy__Completion_Indicator_Faculty__c, reduivy__Completion_Indicator_Student__c
            FROM reduivy__Study_Requirement_Set__c
        ];

        for(reduivy__Study_Requirement_Set__c srs : srsListToUpdate) {
            srs.reduivy__Completion_Indicator_Admin__c = 'NonExistent_Field__c';
            srs.reduivy__Completion_Indicator_Faculty__c = 'NonExistent_Field__c';
            srs.reduivy__Completion_Indicator_Student__c = 'NonExistent_Field__c';
        }
        
        update srsListToUpdate;

        System.runAs(FACULTY_USER) {
            // Complete all requirements in irsLocal
            for (reduivy__Individual_Requirement__c irq : irsLocal.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }

            try {
                update irsLocal.reduivy__Individual_Requirements__r;
                System.Assert.fail('Expected Exception for non-existent field');
            } catch (Exception exp) {
                String expectedError = String.format(Label.Invalid_Object_Field_Error, 
                    new List<String>{'NonExistent_Field__c', IPA_Helper.getApiName()});
                System.Assert.isTrue(exp.getMessage().contains(expectedError), 
                    'Expected error message about field not found. Actual: ' + exp.getMessage());
            }
        }

        Test.stopTest();
    }

    /**
     * @description Test error handling when completion indicator field is not a checkbox/boolean as faculty
     */
    @IsTest
    static void testForUpdate_NonBooleanCompletionField_ThrowsError_AsFaculty() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA()){
            return;
        }
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        transferIRQOwnership(FACULTY_USER.Id);

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');

        List<reduivy__Study_Requirement_Set__c> srsListToUpdate = [
            SELECT Id, reduivy__Completion_Indicator_Admin__c, reduivy__Completion_Indicator_Faculty__c, reduivy__Completion_Indicator_Student__c
            FROM reduivy__Study_Requirement_Set__c
        ];

        // Update SRS with a text field instead of checkbox
        for(reduivy__Study_Requirement_Set__c srs : srsListToUpdate) {
            srs.reduivy__Completion_Indicator_Admin__c = 'Name';
            srs.reduivy__Completion_Indicator_Faculty__c = 'Name';
            srs.reduivy__Completion_Indicator_Student__c = 'Name';
        }
        
        update srsListToUpdate;
        
        System.runAs(FACULTY_USER) {
            // Complete all requirements in irsLocal
            for (reduivy__Individual_Requirement__c irq : irsLocal.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }

            try {
                update irsLocal.reduivy__Individual_Requirements__r;
                System.Assert.fail('Expected Exception for non-boolean field');
            } catch (Exception exp) {
                String expectedError = String.format(Label.Field_Not_Boolean, 
                    new List<String>{'Name', IPA_Helper.getApiName()});
                System.Assert.isTrue(exp.getMessage().contains(expectedError), 
                    'Expected error message about field not being boolean. Actual: ' + exp.getMessage());
            }
        }

        Test.stopTest();
    }

    /**
     * @description Test with IRS that has zero requirements as faculty
     */
    @IsTest
    static void testForUpdate_IRSWithZeroRequirements_IgnoredInCalculation_AsFaculty() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA()){
            return;
        }
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        transferIRQOwnership(FACULTY_USER.Id);

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Program_Application__c ipa = (reduivy__Individual_Program_Application__c)testData.get('ipa');
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');
        reduivy__Individual_Requirement_Set__c irsGeneral = (reduivy__Individual_Requirement_Set__c)testData.get('irsGeneral');
        reduivy__Individual_Requirement_Set__c irsApplication = (reduivy__Individual_Requirement_Set__c)testData.get('irsApplication');
        
        // Delete all requirements from irsLocal to make it have zero requirements
        if (!irsLocal.reduivy__Individual_Requirements__r.isEmpty()) {
            delete irsLocal.reduivy__Individual_Requirements__r;
        }

        System.runAs(FACULTY_USER) {
            // Complete all requirements in other IRS
            for (reduivy__Individual_Requirement__c irq : irsGeneral.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsGeneral.reduivy__Individual_Requirements__r;

            for (reduivy__Individual_Requirement__c irq : irsApplication.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsApplication.reduivy__Individual_Requirements__r;
        }

        // Verify indicator is true (IRS with zero requirements should be ignored)
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 
            'Indicator should be true when IRS with zero requirements is ignored');

        Test.stopTest();
    }

    /**
     * @description Test bulk update with multiple IRS records as faculty
     */
    @IsTest
    static void testForUpdate_BulkUpdate_AllIndicatorsUpdated_AsFaculty() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA()){
            return;
        }
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        transferIRQOwnership(FACULTY_USER.Id);

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Program_Application__c ipa = (reduivy__Individual_Program_Application__c)testData.get('ipa');
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');
        reduivy__Individual_Requirement_Set__c irsGeneral = (reduivy__Individual_Requirement_Set__c)testData.get('irsGeneral');
        reduivy__Individual_Requirement_Set__c irsApplication = (reduivy__Individual_Requirement_Set__c)testData.get('irsApplication');
        
        // Prepare bulk update of all IRQ across all IRS
        List<reduivy__Individual_Requirement__c> allIrqs = new List<reduivy__Individual_Requirement__c>();
        
        for (reduivy__Individual_Requirement__c irq : irsGeneral.reduivy__Individual_Requirements__r) {
            irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
            irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            allIrqs.add(irq);
        }
        
        for (reduivy__Individual_Requirement__c irq : irsLocal.reduivy__Individual_Requirements__r) {
            irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
            irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            allIrqs.add(irq);
        }
        
        for (reduivy__Individual_Requirement__c irq : irsApplication.reduivy__Individual_Requirements__r) {
            irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
            irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            allIrqs.add(irq);
        }

        System.runAs(FACULTY_USER) {
            update allIrqs;
        }

        // Verify indicator is updated correctly
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 
            'Admin indicator should be true after bulk update');

        Test.stopTest();
    }

    /**
     * @description Test with mixed active and inactive IRS - verify only active ones affect calculation as faculty
     */
    @IsTest
    static void testForUpdate_MixedActiveInactive_OnlyActiveConsidered_AsFaculty() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA()){
            return;
        }
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        transferIRQOwnership(FACULTY_USER.Id);

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Program_Application__c ipa = (reduivy__Individual_Program_Application__c)testData.get('ipa');
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');
        reduivy__Individual_Requirement_Set__c irsGeneral = (reduivy__Individual_Requirement_Set__c)testData.get('irsGeneral');
        reduivy__Individual_Requirement_Set__c irsApplication = (reduivy__Individual_Requirement_Set__c)testData.get('irsApplication');
        
        // Set irsGeneral and irsApplication to inactive
        irsGeneral.reduivy__Status__c = IRS_Helper.STATUS_DRAFT;
        irsApplication.reduivy__Status__c = IRS_Helper.STATUS_DRAFT;

        List<reduivy__Individual_Requirement_Set__c> irsToUpdate = new List<reduivy__Individual_Requirement_Set__c>{
            irsGeneral, irsApplication
        };
        update irsToUpdate;

        for (reduivy__Individual_Requirement__c irq : irsLocal.reduivy__Individual_Requirements__r) {
            irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_FACULTY;
        }
        update irsLocal.reduivy__Individual_Requirements__r;
        
        System.runAs(FACULTY_USER) {
            
            // Complete all requirements in irsLocal (only active IRS)
            for (reduivy__Individual_Requirement__c irq : irsLocal.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
            }
            update irsLocal.reduivy__Individual_Requirements__r;
        }

        // Verify indicator is true (only active irsLocal is considered and it's complete)
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Faculty__c'), 
            'Indicator should be true when only active IRS is complete');

        Test.stopTest();
    }

    /**
     * @description Test multiple parent objects - Contact and IPA with same indicators as faculty
     */
    @IsTest
    static void testForUpdate_MultipleParentObjects_BothUpdated_AsFaculty() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA() || !CON_Helper.canRunEvaluationTestForRequirementIndicatorInContact()){
            return;
        }

        User FACULTY_USER = testFactory.getReduFacultyUser();
        transferIRQOwnership(FACULTY_USER.Id);

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Program_Application__c ipa = (reduivy__Individual_Program_Application__c)testData.get('ipa');
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');
        reduivy__Individual_Requirement_Set__c irsGeneral = (reduivy__Individual_Requirement_Set__c)testData.get('irsGeneral');
        reduivy__Individual_Requirement_Set__c irsApplication = (reduivy__Individual_Requirement_Set__c)testData.get('irsApplication');
        
        // Get the contact associated with the IPA
        Contact studentContact = [
            SELECT Id
            FROM Contact
            WHERE Id = :ipa.reduivy__Contact__c
            LIMIT 1
        ];
        
        // Verify initial state - Contact indicators should be false using dynamic field access
        studentContact = queryContact(studentContact.Id);
        System.Assert.areEqual(false, (Boolean) studentContact.get('reduivy__Test_Requirements_Complete_Admin__c'), 
            'Contact Admin indicator should be false initially!');
        System.Assert.areEqual(false, (Boolean) studentContact.get('reduivy__Test_Requirements_Complete_Faculty__c'), 
            'Contact Faculty indicator should be false initially!');
        System.Assert.areEqual(false, (Boolean) studentContact.get('reduivy__Test_Requirements_Complete_Student__c'), 
            'Contact Student indicator should be false initially!');
        
        // Update some SRS to point to Contact instead of IPA
        List<reduivy__Study_Requirement_Set__c> srsListToUpdate = [
            SELECT Id, reduivy__Object__c, reduivy__Sample_Record_Code__c,
                reduivy__Completion_Indicator_Admin__c,
                reduivy__Completion_Indicator_Faculty__c,
                reduivy__Completion_Indicator_Student__c
            FROM reduivy__Study_Requirement_Set__c
            WHERE reduivy__Sample_Record_Code__c IN (:SRS_LOCAL, :SRS_GENERAL)
        ];
        
        for (reduivy__Study_Requirement_Set__c srs : srsListToUpdate) {
            // Change object to Contact
            srs.reduivy__Object__c = CON_Helper.getApiName();
            // Keep the same indicator fields
            srs.reduivy__Completion_Indicator_Admin__c = 'reduivy__Test_Requirements_Complete_Admin__c';
            srs.reduivy__Completion_Indicator_Faculty__c = 'reduivy__Test_Requirements_Complete_Faculty__c';
            srs.reduivy__Completion_Indicator_Student__c = 'reduivy__Test_Requirements_Complete_Student__c';
        }
        
        update srsListToUpdate;
        
        // Update IRS to point to Contact for Local and General
        irsLocal.reduivy__Contact__c = studentContact.Id;
        irsGeneral.reduivy__Contact__c = studentContact.Id;
        
        List<reduivy__Individual_Requirement_Set__c> irsToUpdate = new List<reduivy__Individual_Requirement_Set__c>{
            irsLocal, irsGeneral
        };
        
        update irsToUpdate;

        List<reduivy__Individual_Requirement__c> allIRQs = new List<reduivy__Individual_Requirement__c>();

        if (irsLocal.reduivy__Individual_Requirements__r != null) {
            allIRQs.addAll(irsLocal.reduivy__Individual_Requirements__r);
        }
        if (irsGeneral.reduivy__Individual_Requirements__r != null) {
            allIRQs.addAll(irsGeneral.reduivy__Individual_Requirements__r);
        }
        if (irsApplication.reduivy__Individual_Requirements__r != null) {
            allIRQs.addAll(irsApplication.reduivy__Individual_Requirements__r);
        }

        for (reduivy__Individual_Requirement__c irq : allIRQs) {
            irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_FACULTY;
        }

        if (!allIRQs.isEmpty()) {
            update allIRQs;
        }
        
        // Now we have:
        // - irsLocal -> Contact (Faculty visibility)
        // - irsGeneral -> Contact (Faculty visibility)
        // - irsApplication -> IPA (Faculty visibility)
        
        System.runAs(FACULTY_USER) {
            // Complete all requirements in irsLocal (Contact parent - Faculty visibility)
            for (reduivy__Individual_Requirement__c irq : irsLocal.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
            }
            update irsLocal.reduivy__Individual_Requirements__r;
        }
        
        // Verify Contact indicator is still false (irsGeneral not complete yet)
        studentContact = queryContact(studentContact.Id);
        System.Assert.areEqual(false, (Boolean) studentContact.get('reduivy__Test_Requirements_Complete_Faculty__c'), 
            'Contact Faculty indicator should be false with one IRS incomplete!');
        
        System.runAs(FACULTY_USER) {
            // Complete all requirements in irsGeneral (Contact parent - Faculty visibility)
            for (reduivy__Individual_Requirement__c irq : irsGeneral.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
            }
            update irsGeneral.reduivy__Individual_Requirements__r;
        }
        
        // Verify Contact indicator is now true (both IRS complete)
        studentContact = queryContact(studentContact.Id);
        System.Assert.areEqual(true, (Boolean) studentContact.get('reduivy__Test_Requirements_Complete_Faculty__c'), 
            'Contact Faculty indicator should be true with all Contact IRS complete!');
        
        // Verify IPA indicator is still false (irsApplication not complete yet)
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(false, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Faculty__c'), 
            'IPA Faculty indicator should be false with IPA IRS incomplete!');
        
        System.runAs(FACULTY_USER) {
            // Complete all requirements in irsApplication (IPA parent - Admin visibility)
            for (reduivy__Individual_Requirement__c irq : irsApplication.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
            }
            update irsApplication.reduivy__Individual_Requirements__r;
        }
        
        // Verify IPA indicator is now true
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Faculty__c'), 
            'IPA Faculty indicator should be true with all IPA IRS complete!');
        
        // Verify Contact indicator remains true
        studentContact = queryContact(studentContact.Id);
        System.Assert.areEqual(true, (Boolean) studentContact.get('reduivy__Test_Requirements_Complete_Faculty__c'), 
            'Contact Faculty indicator should remain true!');
        
        Test.stopTest();
    }

    /**
     * @description Test multiple parent objects with mixed visibility as faculty
     */
    @IsTest
    static void testForUpdate_MultipleParentObjects_MixedVisibility_AsFaculty() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA() || !CON_Helper.canRunEvaluationTestForRequirementIndicatorInContact()){
            return;
        }

        User FACULTY_USER = testFactory.getReduFacultyUser();
        transferIRQOwnership(FACULTY_USER.Id);

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Program_Application__c ipa = (reduivy__Individual_Program_Application__c)testData.get('ipa');
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');
        reduivy__Individual_Requirement_Set__c irsGeneral = (reduivy__Individual_Requirement_Set__c)testData.get('irsGeneral');
        reduivy__Individual_Requirement_Set__c irsApplication = (reduivy__Individual_Requirement_Set__c)testData.get('irsApplication');
        
        // Get the contact associated with the IPA
        Contact studentContact = [
            SELECT Id
            FROM Contact
            WHERE Id = :ipa.reduivy__Contact__c
            LIMIT 1
        ];
        
        // Update SRS to point to different objects
        List<reduivy__Study_Requirement_Set__c> srsListToUpdate = [
            SELECT Id, reduivy__Object__c, reduivy__Sample_Record_Code__c,
                reduivy__Completion_Indicator_Admin__c,
                reduivy__Completion_Indicator_Faculty__c,
                reduivy__Completion_Indicator_Student__c
            FROM reduivy__Study_Requirement_Set__c
            WHERE reduivy__Sample_Record_Code__c IN (:SRS_LOCAL)
        ];
        
        for (reduivy__Study_Requirement_Set__c srs : srsListToUpdate) {
            // Change object to Contact
            srs.reduivy__Object__c = CON_Helper.getApiName();
            srs.reduivy__Completion_Indicator_Admin__c = 'reduivy__Test_Requirements_Complete_Admin__c';
            srs.reduivy__Completion_Indicator_Faculty__c = 'reduivy__Test_Requirements_Complete_Faculty__c';
            srs.reduivy__Completion_Indicator_Student__c = 'reduivy__Test_Requirements_Complete_Student__c';
        }
        
        update srsListToUpdate;
        
        // Update IRS to point to Contact for Local and General
        irsLocal.reduivy__Contact__c = studentContact.Id;
        irsGeneral.reduivy__Contact__c = studentContact.Id;
        
        List<reduivy__Individual_Requirement_Set__c> irsToUpdateParent = new List<reduivy__Individual_Requirement_Set__c>{
            irsLocal, irsGeneral
        };
        
        update irsToUpdateParent;

        // List for Contact IRS (irsLocal + irsGeneral)
        List<reduivy__Individual_Requirement__c> contactIRQs = new List<reduivy__Individual_Requirement__c>();

        if (irsLocal.reduivy__Individual_Requirements__r != null) {
            contactIRQs.addAll(irsLocal.reduivy__Individual_Requirements__r);
        }
        if (irsGeneral.reduivy__Individual_Requirements__r != null) {
            contactIRQs.addAll(irsGeneral.reduivy__Individual_Requirements__r);
        }

        // Update Contact IRS requirements
        for (reduivy__Individual_Requirement__c irq : contactIRQs) {
            irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_FACULTY;
        }
        if (!contactIRQs.isEmpty()) {
            update contactIRQs;
        }

        // List for IPA IRS (irsApplication)
        List<reduivy__Individual_Requirement__c> ipaIRQs = new List<reduivy__Individual_Requirement__c>();

        if (irsApplication.reduivy__Individual_Requirements__r != null) {
            ipaIRQs.addAll(irsApplication.reduivy__Individual_Requirements__r);
        }

        // Update IPA IRS requirements
        for (reduivy__Individual_Requirement__c irq : ipaIRQs) {
            irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT;
        }
        if (!ipaIRQs.isEmpty()) {
            update ipaIRQs;
        }
        
        System.runAs(FACULTY_USER) {
            // Set Contact IRS (irsLocal, irsGeneral) to Faculty visibility and complete them
            for (reduivy__Individual_Requirement__c irq : irsLocal.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
            }
            update irsLocal.reduivy__Individual_Requirements__r;
            
            for (reduivy__Individual_Requirement__c irq : irsGeneral.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
            }
            update irsGeneral.reduivy__Individual_Requirements__r;
        
            // Set IPA IRS (irsApplication) to Student visibility and complete them
            for (reduivy__Individual_Requirement__c irq : irsApplication.reduivy__Individual_Requirements__r) {
                irq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
            }
            update irsApplication.reduivy__Individual_Requirements__r;
        }
        
        // Verify Contact Faculty indicator is true
        studentContact = queryContact(studentContact.Id);
        System.Assert.areEqual(true, (Boolean) studentContact.get('reduivy__Test_Requirements_Complete_Faculty__c'), 
            'Contact Faculty indicator should be true!');
        System.Assert.areEqual(true, (Boolean) studentContact.get('reduivy__Test_Requirements_Complete_Admin__c'), 
            'Contact Admin indicator should be true!');
        
        // Verify IPA Student indicator is true
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Student__c'), 
            'IPA Student indicator should be true!');
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 
            'IPA Admin indicator should be true!');
        
        Test.stopTest();
    }

    /**
     * @description Test AfterInsert - IRS created with completed requirements should update parent as faculty
     */
    @IsTest
    static void testForInsert_NewIRSWithCompletedRequirements_UpdatesParent_AsFaculty() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA()){
            return;
        }

        User FACULTY_USER = testFactory.getReduFacultyUser();
        transferIRQOwnership(FACULTY_USER.Id);

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Program_Application__c ipa = (reduivy__Individual_Program_Application__c)testData.get('ipa');
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');
        reduivy__Individual_Requirement_Set__c irsGeneral = (reduivy__Individual_Requirement_Set__c)testData.get('irsGeneral');
        reduivy__Individual_Requirement_Set__c irsApplication = (reduivy__Individual_Requirement_Set__c)testData.get('irsApplication');
        
        System.runAs(FACULTY_USER) {
            // Complete all existing IRS requirements
            for (reduivy__Individual_Requirement__c irq : irsGeneral.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsGeneral.reduivy__Individual_Requirements__r;

            for (reduivy__Individual_Requirement__c irq : irsLocal.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsLocal.reduivy__Individual_Requirements__r;

            for (reduivy__Individual_Requirement__c irq : irsApplication.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsApplication.reduivy__Individual_Requirements__r;
        }

        // Verify parent is complete
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 
            'IPA should be complete before new IRS!');

        // Create a new IRS manually (simulating AfterInsert)
        // Get SRS
        List<reduivy__Study_Requirement_Set__c> srsList = [
            SELECT Id, reduivy__Object__c
            FROM reduivy__Study_Requirement_Set__c
            WHERE reduivy__Sample_Record_Code__c = :SRS_LOCAL
            LIMIT 1
        ];

        // Create new IRS
        reduivy__Individual_Requirement_Set__c newIrs = new reduivy__Individual_Requirement_Set__c(
            reduivy__Study_Requirement_Set__c = srsList[0].Id,
            reduivy__Individual_Program_Application__c = ipa.Id,
            reduivy__Status__c = IRS_Helper.STATUS_ACTIVE,
            reduivy__Total_Requirement__c = 1,
            reduivy__Total_Reviewed__c = 0, // Incomplete
            reduivy__Total_Requirement_Faculty__c = 0,
            reduivy__Total_Requirement_Student__c = 0
        );

        System.runAs(FACULTY_USER) {
            insert newIrs;
        }

        // Verify parent indicator is now false (new incomplete IRS added)
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(false, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 
            'IPA should be incomplete after new incomplete IRS inserted!');

        Test.stopTest();
    }

    /**
     * @description Test error handling when more than 5 different parent objects are being processed as faculty
     */
    @IsTest
    static void testForUpdate_MoreThan5ParentObjects_ThrowsError_AsFaculty() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA()){
            return;
        }
        
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Program_Application__c ipa = (reduivy__Individual_Program_Application__c)testData.get('ipa');
        
        List<reduivy__Study_Requirement_Set__c> srsListToCreate = new List<reduivy__Study_Requirement_Set__c>();
        
        // Create 6 SRS pointing to different objects
        List<String> parentObjects = new List<String>{
            'Account',
            'Contact', 
            'Opportunity',
            'Lead',
            'Case',
            'Campaign'
        };
        
        for (Integer i = 0; i < 6; i++) {
            reduivy__Study_Requirement_Set__c srs = new reduivy__Study_Requirement_Set__c(
                Name = 'Test SRS ' + i,
                reduivy__Object__c = parentObjects[i],
                reduivy__Sample_Record_Code__c = 'TEST_SRS_' + i,
                reduivy__Completion_Indicator_Admin__c = 'reduivy__Test_Requirements_Complete_Admin__c',
                reduivy__Completion_Indicator_Faculty__c = 'reduivy__Test_Requirements_Complete_Faculty__c',
                reduivy__Completion_Indicator_Student__c = 'reduivy__Test_Requirements_Complete_Student__c',
                reduivy__Status__c = SRS_Helper.STATUS_ACTIVE,
                reduivy__Requirement_Generation_Mode__c = IRS_Helper.REQUIREMENT_GENERATION_MODE_MANUAL
            );
            srsListToCreate.add(srs);
        }
        
        insert srsListToCreate;
        
        // Create 6 IRS records, each pointing to a different SRS (thus 6 different parent objects)
        List<reduivy__Individual_Requirement_Set__c> irsList = new List<reduivy__Individual_Requirement_Set__c>();
        
        for (Integer i = 0; i < 6; i++) {
            reduivy__Individual_Requirement_Set__c irs = new reduivy__Individual_Requirement_Set__c(
                reduivy__Study_Requirement_Set__c = srsListToCreate[i].Id,
                reduivy__Individual_Program_Application__c = ipa.Id,
                reduivy__Status__c = IRS_Helper.STATUS_ACTIVE,
                reduivy__Total_Requirement__c = 1,
                reduivy__Total_Reviewed__c = 0,
                reduivy__Total_Requirement_Faculty__c = 1,
                reduivy__Total_Requirement_Student__c = 1
            );
            irsList.add(irs);
        }
        
        System.runAs(FACULTY_USER) {
            try {
                insert irsList;
                System.Assert.fail('Expected Exception for processing more than 5 parent objects');
            } catch (Exception exp) {
                String expectedError = String.format(Label.Too_Many_Parent_Objects_In_Transaction,
                            new List<String>{SRS_Helper.getObjectLabel(), String.join(parentObjects, ',')});
                System.Assert.isTrue(exp.getMessage().contains(expectedError), 
                    'Expected error message about too many parent objects. Actual: ' + exp.getMessage());
            }
        }

        Test.stopTest();
    }

    /**
     * @description Test all requirements complete in all IRS - should set indicators to true as student
     */
    @IsTest
    static void testForUpdate_AllIRSComplete_AllIndicatorsTrue_AsStudent() {

        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA()){
            return;
        }

        User studentUser = testFactory.getStudentUser();
        transferIRQOwnership(studentUser.Id);

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Program_Application__c ipa = (reduivy__Individual_Program_Application__c)testData.get('ipa');
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');
        reduivy__Individual_Requirement_Set__c irsGeneral = (reduivy__Individual_Requirement_Set__c)testData.get('irsGeneral');
        reduivy__Individual_Requirement_Set__c irsApplication = (reduivy__Individual_Requirement_Set__c)testData.get('irsApplication');

        // Verify initial state - all indicators should be false
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(false, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 'Admin indicator should be false initially!');
        System.Assert.areEqual(false, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Faculty__c'), 'Faculty indicator should be false initially!');
        System.Assert.areEqual(false, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Student__c'), 'Student indicator should be false initially!');

        System.runAs(studentUser) {
            // Complete all requirements in irsGeneral (Admin visibility)
            for (reduivy__Individual_Requirement__c irq : irsGeneral.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsGeneral.reduivy__Individual_Requirements__r;
        }

        // Verify admin indicator is still false (irsLocal and irsApplication not complete yet)
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(false, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 'Admin indicator should be false with two IRS incomplete!');

        System.runAs(studentUser) {
            // Complete all requirements in irsLocal (Admin visibility)
            for (reduivy__Individual_Requirement__c irq : irsLocal.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsLocal.reduivy__Individual_Requirements__r;
        }

        // Verify admin indicator is still false (irsApplication not complete yet)
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(false, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 'Admin indicator should be false with one IRS incomplete!');

        System.runAs(studentUser) {
            // Complete all requirements in irsApplication (Admin visibility)
            for (reduivy__Individual_Requirement__c irq : irsApplication.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsApplication.reduivy__Individual_Requirements__r;
        }
        
        // Verify admin indicator is now true (all 3 IRS complete)
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 'Admin indicator should be true with all IRS complete!');

        Test.stopTest();
    }

    /**
     * @description Test one IRS incomplete - should keep indicator false  as student
     */
    @IsTest
    static void testForUpdate_OneIRSIncomplete_IndicatorFalse_AsStudent() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA()){
            return;
        }

        User studentUser = testFactory.getStudentUser();
        transferIRQOwnership(studentUser.Id);

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Program_Application__c ipa = (reduivy__Individual_Program_Application__c)testData.get('ipa');
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');
        reduivy__Individual_Requirement_Set__c irsGeneral = (reduivy__Individual_Requirement_Set__c)testData.get('irsGeneral');
        reduivy__Individual_Requirement_Set__c irsApplication = (reduivy__Individual_Requirement_Set__c)testData.get('irsApplication');
        
        System.runAs(studentUser) {
            // Complete all requirements in irsGeneral
            for (reduivy__Individual_Requirement__c irq : irsGeneral.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsGeneral.reduivy__Individual_Requirements__r;

            // Complete all requirements in irsApplication
            for (reduivy__Individual_Requirement__c irq : irsApplication.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsApplication.reduivy__Individual_Requirements__r;

            // Leave irsLocal incomplete (complete all except the last one if multiple requirements exist)
            if (irsLocal.reduivy__Individual_Requirements__r.size() > 1) {
                List<reduivy__Individual_Requirement__c> localIrqsToComplete = new List<reduivy__Individual_Requirement__c>();
                for (Integer i = 0; i < irsLocal.reduivy__Individual_Requirements__r.size() - 1; i++) {
                    reduivy__Individual_Requirement__c irq = irsLocal.reduivy__Individual_Requirements__r[i];
                    irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                    irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
                    localIrqsToComplete.add(irq);
                }
                if (!localIrqsToComplete.isEmpty()) {
                    update localIrqsToComplete;
                }
            }
        }

        // Verify admin indicator is false (one IRS incomplete)
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(false, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 'Admin indicator should be false when any IRS incomplete!');

        Test.stopTest();
    }

    /**
     * @description Test Faculty visibility - complete all Faculty visible requirements as student
     */
    @IsTest
    static void testForUpdate_FacultyVisibility_AllComplete_IndicatorTrue_AsStudent() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA()){
            return;
        }

        User studentUser = testFactory.getStudentUser();
        transferIRQOwnership(studentUser.Id);

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Program_Application__c ipa = (reduivy__Individual_Program_Application__c)testData.get('ipa');
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');
        reduivy__Individual_Requirement_Set__c irsGeneral = (reduivy__Individual_Requirement_Set__c)testData.get('irsGeneral');
        reduivy__Individual_Requirement_Set__c irsApplication = (reduivy__Individual_Requirement_Set__c)testData.get('irsApplication');
        
        System.runAs(studentUser) {
            // Set all requirements to Faculty visibility and complete them
            for (reduivy__Individual_Requirement__c irq : irsGeneral.reduivy__Individual_Requirements__r) {
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_FACULTY;
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
            }
            update irsGeneral.reduivy__Individual_Requirements__r;

            for (reduivy__Individual_Requirement__c irq : irsLocal.reduivy__Individual_Requirements__r) {
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_FACULTY;
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
            }
            update irsLocal.reduivy__Individual_Requirements__r;

            for (reduivy__Individual_Requirement__c irq : irsApplication.reduivy__Individual_Requirements__r) {
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_FACULTY;
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
            }
            update irsApplication.reduivy__Individual_Requirements__r;
        }

        // Verify Faculty indicator is true
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Faculty__c'), 'Faculty indicator should be true with all Faculty requirements complete!');

        Test.stopTest();
    }

    /**
     * @description Test Student visibility - complete all Student visible requirements as student
     */
    @IsTest
    static void testForUpdate_StudentVisibility_AllComplete_IndicatorTrue_AsStudent() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA()){
            return;
        }
        
        User studentUser = testFactory.getStudentUser();
        transferIRQOwnership(studentUser.Id);

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Program_Application__c ipa = (reduivy__Individual_Program_Application__c)testData.get('ipa');
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');
        reduivy__Individual_Requirement_Set__c irsGeneral = (reduivy__Individual_Requirement_Set__c)testData.get('irsGeneral');
        reduivy__Individual_Requirement_Set__c irsApplication = (reduivy__Individual_Requirement_Set__c)testData.get('irsApplication');
        
        System.runAs(studentUser) {
            // Set all requirements to Student visibility and submit them
            for (reduivy__Individual_Requirement__c irq : irsGeneral.reduivy__Individual_Requirements__r) {
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT;
                irq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
            }
            update irsGeneral.reduivy__Individual_Requirements__r;

            for (reduivy__Individual_Requirement__c irq : irsLocal.reduivy__Individual_Requirements__r) {
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT;
                irq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
            }
            update irsLocal.reduivy__Individual_Requirements__r;

            for (reduivy__Individual_Requirement__c irq : irsApplication.reduivy__Individual_Requirements__r) {
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT;
                irq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
            }
            update irsApplication.reduivy__Individual_Requirements__r;
        }

        // Verify Student indicator is true
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Student__c'), 'Student indicator should be true with all Student requirements submitted!');

        Test.stopTest();
    }

    /**
     * @description Test mixed visibility - verify each indicator tracks its own requirements as student
     */
    @IsTest
    static void testForUpdate_MixedVisibility_IndependentIndicators_AsStudent() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA()){
            return;
        }
        
        User studentUser = testFactory.getStudentUser();
        transferIRQOwnership(studentUser.Id);

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Program_Application__c ipa = (reduivy__Individual_Program_Application__c)testData.get('ipa');
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');
        reduivy__Individual_Requirement_Set__c irsGeneral = (reduivy__Individual_Requirement_Set__c)testData.get('irsGeneral');
        reduivy__Individual_Requirement_Set__c irsApplication = (reduivy__Individual_Requirement_Set__c)testData.get('irsApplication');
        
        System.runAs(studentUser) {
            // irsGeneral: Set requirements to different visibilities and complete them
            List<reduivy__Individual_Requirement__c> generalIrqs = irsGeneral.reduivy__Individual_Requirements__r;
            if (generalIrqs.size() > 0) {
                // Set first requirement to Admin
                generalIrqs[0].reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
                generalIrqs[0].reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                
                // Set remaining requirements to Faculty
                for (Integer i = 1; i < generalIrqs.size(); i++) {
                    generalIrqs[i].reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_FACULTY;
                    generalIrqs[i].reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                }
            }
            update generalIrqs;

            // irsLocal: Set requirements to different visibilities
            List<reduivy__Individual_Requirement__c> localIrqs = irsLocal.reduivy__Individual_Requirements__r;
            if (localIrqs.size() > 0) {
                // Set first requirement to Admin
                localIrqs[0].reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
                localIrqs[0].reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                
                // Set remaining requirements to Student
                for (Integer i = 1; i < localIrqs.size(); i++) {
                    localIrqs[i].reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT;
                    localIrqs[i].reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
                    localIrqs[i].reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                }
            }
            update localIrqs;

            // irsApplication: Set all to Admin and complete them
            for (reduivy__Individual_Requirement__c irq : irsApplication.reduivy__Individual_Requirements__r) {
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
            }
            update irsApplication.reduivy__Individual_Requirements__r;
        }

        // Verify indicators
        ipa = queryIPA(ipa.Id);
        // Admin: All 3 IRS have Admin requirements complete
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 'Admin indicator should be true!');
        // Faculty: Only irsGeneral has student requirements complete, others have none
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Faculty__c'), 'Faculty indicator should be true!');
        // Student: Only irsLocal has Student requirements complete, others have none
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Student__c'), 'Student indicator should be true!');

        Test.stopTest();
    }

    /**
     * @description Test changing requirement from complete to incomplete as student
     */
    @IsTest
    static void testForUpdate_RevertCompletion_IndicatorsFalse_AsStudent() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA()){
            return;
        }
        
        User studentUser = testFactory.getStudentUser();
        transferIRQOwnership(studentUser.Id);

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Program_Application__c ipa = (reduivy__Individual_Program_Application__c)testData.get('ipa');
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');
        reduivy__Individual_Requirement_Set__c irsGeneral = (reduivy__Individual_Requirement_Set__c)testData.get('irsGeneral');
        reduivy__Individual_Requirement_Set__c irsApplication = (reduivy__Individual_Requirement_Set__c)testData.get('irsApplication');
        
        System.runAs(studentUser) {
            // Complete all requirements in all IRS
            for (reduivy__Individual_Requirement__c irq : irsGeneral.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsGeneral.reduivy__Individual_Requirements__r;

            for (reduivy__Individual_Requirement__c irq : irsLocal.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsLocal.reduivy__Individual_Requirements__r;

            for (reduivy__Individual_Requirement__c irq : irsApplication.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsApplication.reduivy__Individual_Requirements__r;
        }

        // Verify indicator is true
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 'Admin indicator should be true!');

        System.runAs(studentUser) {
            // Revert any one requirement to incomplete
            if (!irsLocal.reduivy__Individual_Requirements__r.isEmpty()) {
                reduivy__Individual_Requirement__c irqToRevert = irsLocal.reduivy__Individual_Requirements__r[0];
                irqToRevert.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_OPEN;
                update irqToRevert;
            }
        }

        // Verify indicator is now false
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(false, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 'Admin indicator should be false after reverting!');

        Test.stopTest();
    }

    /**
     * @description Test error handling when completion indicator field doesn't exist on parent object as student
     */
    @IsTest
    static void testForUpdate_InvalidCompletionField_ThrowsError_AsStudent() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA()){
            return;
        }
        
        User studentUser = testFactory.getStudentUser();
        transferIRQOwnership(studentUser.Id);

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');

        List<reduivy__Study_Requirement_Set__c> srsListToUpdate = [
            SELECT Id, reduivy__Completion_Indicator_Admin__c, reduivy__Completion_Indicator_Faculty__c, reduivy__Completion_Indicator_Student__c
            FROM reduivy__Study_Requirement_Set__c
        ];

        for(reduivy__Study_Requirement_Set__c srs : srsListToUpdate) {
            srs.reduivy__Completion_Indicator_Admin__c = 'NonExistent_Field__c';
            srs.reduivy__Completion_Indicator_Faculty__c = 'NonExistent_Field__c';
            srs.reduivy__Completion_Indicator_Student__c = 'NonExistent_Field__c';
        }
        
        update srsListToUpdate;

        System.runAs(studentUser) {
            // Complete all requirements in irsLocal
            for (reduivy__Individual_Requirement__c irq : irsLocal.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }

            try {
                update irsLocal.reduivy__Individual_Requirements__r;
                System.Assert.fail('Expected Exception for non-existent field');
            } catch (Exception exp) {
                String expectedError = String.format(Label.Invalid_Object_Field_Error, 
                    new List<String>{'NonExistent_Field__c', IPA_Helper.getApiName()});
                System.Assert.isTrue(exp.getMessage().contains(expectedError), 
                    'Expected error message about field not found. Actual: ' + exp.getMessage());
            }
        }

        Test.stopTest();
    }

    /**
     * @description Test error handling when completion indicator field is not a checkbox/boolean as student
     */
    @IsTest
    static void testForUpdate_NonBooleanCompletionField_ThrowsError_AsStudent() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA()){
            return;
        }
        
        User studentUser = testFactory.getStudentUser();
        transferIRQOwnership(studentUser.Id);

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');

        List<reduivy__Study_Requirement_Set__c> srsListToUpdate = [
            SELECT Id, reduivy__Completion_Indicator_Admin__c, reduivy__Completion_Indicator_Faculty__c, reduivy__Completion_Indicator_Student__c
            FROM reduivy__Study_Requirement_Set__c
        ];

        // Update SRS with a text field instead of checkbox
        for(reduivy__Study_Requirement_Set__c srs : srsListToUpdate) {
            srs.reduivy__Completion_Indicator_Admin__c = 'Name';
            srs.reduivy__Completion_Indicator_Faculty__c = 'Name';
            srs.reduivy__Completion_Indicator_Student__c = 'Name';
        }
        
        update srsListToUpdate;
        
        System.runAs(studentUser) {
            // Complete all requirements in irsLocal
            for (reduivy__Individual_Requirement__c irq : irsLocal.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }

            try {
                update irsLocal.reduivy__Individual_Requirements__r;
                System.Assert.fail('Expected Exception for non-boolean field');
            } catch (Exception exp) {
                String expectedError = String.format(Label.Field_Not_Boolean, 
                    new List<String>{'Name', IPA_Helper.getApiName()});
                System.Assert.isTrue(exp.getMessage().contains(expectedError), 
                    'Expected error message about field not being boolean. Actual: ' + exp.getMessage());
            }
        }

        Test.stopTest();
    }

    /**
     * @description Test with IRS that has zero requirements as student
     */
    @IsTest
    static void testForUpdate_IRSWithZeroRequirements_IgnoredInCalculation_AsStudent() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA()){
            return;
        }
        
        User studentUser = testFactory.getStudentUser();
        transferIRQOwnership(studentUser.Id);

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Program_Application__c ipa = (reduivy__Individual_Program_Application__c)testData.get('ipa');
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');
        reduivy__Individual_Requirement_Set__c irsGeneral = (reduivy__Individual_Requirement_Set__c)testData.get('irsGeneral');
        reduivy__Individual_Requirement_Set__c irsApplication = (reduivy__Individual_Requirement_Set__c)testData.get('irsApplication');
        
        // Delete all requirements from irsLocal to make it have zero requirements
        if (!irsLocal.reduivy__Individual_Requirements__r.isEmpty()) {
            delete irsLocal.reduivy__Individual_Requirements__r;
        }

        System.runAs(studentUser) {
            // Complete all requirements in other IRS
            for (reduivy__Individual_Requirement__c irq : irsGeneral.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsGeneral.reduivy__Individual_Requirements__r;

            for (reduivy__Individual_Requirement__c irq : irsApplication.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsApplication.reduivy__Individual_Requirements__r;
        }

        // Verify indicator is true (IRS with zero requirements should be ignored)
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 
            'Indicator should be true when IRS with zero requirements is ignored');

        Test.stopTest();
    }

    /**
     * @description Test bulk update with multiple IRS records as student
     */
    @IsTest
    static void testForUpdate_BulkUpdate_AllIndicatorsUpdated_AsStudent() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA()){
            return;
        }
        
        User studentUser = testFactory.getStudentUser();
        transferIRQOwnership(studentUser.Id);

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Program_Application__c ipa = (reduivy__Individual_Program_Application__c)testData.get('ipa');
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');
        reduivy__Individual_Requirement_Set__c irsGeneral = (reduivy__Individual_Requirement_Set__c)testData.get('irsGeneral');
        reduivy__Individual_Requirement_Set__c irsApplication = (reduivy__Individual_Requirement_Set__c)testData.get('irsApplication');
        
        // Prepare bulk update of all IRQ across all IRS
        List<reduivy__Individual_Requirement__c> allIrqs = new List<reduivy__Individual_Requirement__c>();
        
        for (reduivy__Individual_Requirement__c irq : irsGeneral.reduivy__Individual_Requirements__r) {
            irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
            irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            allIrqs.add(irq);
        }
        
        for (reduivy__Individual_Requirement__c irq : irsLocal.reduivy__Individual_Requirements__r) {
            irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
            irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            allIrqs.add(irq);
        }
        
        for (reduivy__Individual_Requirement__c irq : irsApplication.reduivy__Individual_Requirements__r) {
            irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
            irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            allIrqs.add(irq);
        }

        System.runAs(studentUser) {
            update allIrqs;
        }

        // Verify indicator is updated correctly
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 
            'Admin indicator should be true after bulk update');

        Test.stopTest();
    }

    /**
     * @description Test with mixed active and inactive IRS - verify only active ones affect calculation as student
     */
    @IsTest
    static void testForUpdate_MixedActiveInactive_OnlyActiveConsidered_AsStudent() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA()){
            return;
        }
        
        User studentUser = testFactory.getStudentUser();
        transferIRQOwnership(studentUser.Id);

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Program_Application__c ipa = (reduivy__Individual_Program_Application__c)testData.get('ipa');
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');
        reduivy__Individual_Requirement_Set__c irsGeneral = (reduivy__Individual_Requirement_Set__c)testData.get('irsGeneral');
        reduivy__Individual_Requirement_Set__c irsApplication = (reduivy__Individual_Requirement_Set__c)testData.get('irsApplication');
        
        // Set irsGeneral and irsApplication to inactive
        irsGeneral.reduivy__Status__c = IRS_Helper.STATUS_DRAFT;
        irsApplication.reduivy__Status__c = IRS_Helper.STATUS_DRAFT;

        List<reduivy__Individual_Requirement_Set__c> irsToUpdate = new List<reduivy__Individual_Requirement_Set__c>{
            irsGeneral, irsApplication
        };
        update irsToUpdate;

        for (reduivy__Individual_Requirement__c irq : irsLocal.reduivy__Individual_Requirements__r) {
            irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_FACULTY;
        }
        update irsLocal.reduivy__Individual_Requirements__r;
        
        System.runAs(studentUser) {
            
            // Complete all requirements in irsLocal (only active IRS)
            for (reduivy__Individual_Requirement__c irq : irsLocal.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
            }
            update irsLocal.reduivy__Individual_Requirements__r;
        }

        // Verify indicator is true (only active irsLocal is considered and it's complete)
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Faculty__c'), 
            'Indicator should be true when only active IRS is complete');

        Test.stopTest();
    }

    /**
     * @description Test multiple parent objects - Contact and IPA with same indicators as student
     */
    @IsTest
    static void testForUpdate_MultipleParentObjects_BothUpdated_AsStudent() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA() || !CON_Helper.canRunEvaluationTestForRequirementIndicatorInContact()){
            return;
        }

        User studentUser = testFactory.getStudentUser();
        transferIRQOwnership(studentUser.Id);

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Program_Application__c ipa = (reduivy__Individual_Program_Application__c)testData.get('ipa');
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');
        reduivy__Individual_Requirement_Set__c irsGeneral = (reduivy__Individual_Requirement_Set__c)testData.get('irsGeneral');
        reduivy__Individual_Requirement_Set__c irsApplication = (reduivy__Individual_Requirement_Set__c)testData.get('irsApplication');
        
        // Get the contact associated with the IPA
        Contact studentContact = [
            SELECT Id
            FROM Contact
            WHERE Id = :ipa.reduivy__Contact__c
            LIMIT 1
        ];
        
        // Verify initial state - Contact indicators should be false using dynamic field access
        studentContact = queryContact(studentContact.Id);
        System.Assert.areEqual(false, (Boolean) studentContact.get('reduivy__Test_Requirements_Complete_Admin__c'), 
            'Contact Admin indicator should be false initially!');
        System.Assert.areEqual(false, (Boolean) studentContact.get('reduivy__Test_Requirements_Complete_Faculty__c'), 
            'Contact Faculty indicator should be false initially!');
        System.Assert.areEqual(false, (Boolean) studentContact.get('reduivy__Test_Requirements_Complete_Student__c'), 
            'Contact Student indicator should be false initially!');
        
        // Update some SRS to point to Contact instead of IPA
        List<reduivy__Study_Requirement_Set__c> srsListToUpdate = [
            SELECT Id, reduivy__Object__c, reduivy__Sample_Record_Code__c,
                reduivy__Completion_Indicator_Admin__c,
                reduivy__Completion_Indicator_Faculty__c,
                reduivy__Completion_Indicator_Student__c
            FROM reduivy__Study_Requirement_Set__c
            WHERE reduivy__Sample_Record_Code__c IN (:SRS_LOCAL, :SRS_GENERAL)
        ];
        
        for (reduivy__Study_Requirement_Set__c srs : srsListToUpdate) {
            // Change object to Contact
            srs.reduivy__Object__c = CON_Helper.getApiName();
            // Keep the same indicator fields
            srs.reduivy__Completion_Indicator_Admin__c = 'reduivy__Test_Requirements_Complete_Admin__c';
            srs.reduivy__Completion_Indicator_Faculty__c = 'reduivy__Test_Requirements_Complete_Faculty__c';
            srs.reduivy__Completion_Indicator_Student__c = 'reduivy__Test_Requirements_Complete_Student__c';
        }
        
        update srsListToUpdate;
        
        // Update IRS to point to Contact for Local and General
        irsLocal.reduivy__Contact__c = studentContact.Id;
        irsGeneral.reduivy__Contact__c = studentContact.Id;
        
        List<reduivy__Individual_Requirement_Set__c> irsToUpdate = new List<reduivy__Individual_Requirement_Set__c>{
            irsLocal, irsGeneral
        };
        
        update irsToUpdate;

        List<reduivy__Individual_Requirement__c> allIRQs = new List<reduivy__Individual_Requirement__c>();

        if (irsLocal.reduivy__Individual_Requirements__r != null) {
            allIRQs.addAll(irsLocal.reduivy__Individual_Requirements__r);
        }
        if (irsGeneral.reduivy__Individual_Requirements__r != null) {
            allIRQs.addAll(irsGeneral.reduivy__Individual_Requirements__r);
        }
        if (irsApplication.reduivy__Individual_Requirements__r != null) {
            allIRQs.addAll(irsApplication.reduivy__Individual_Requirements__r);
        }

        for (reduivy__Individual_Requirement__c irq : allIRQs) {
            irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_FACULTY;
        }

        if (!allIRQs.isEmpty()) {
            update allIRQs;
        }
        
        // Now we have:
        // - irsLocal -> Contact (Faculty visibility)
        // - irsGeneral -> Contact (Faculty visibility)
        // - irsApplication -> IPA (Faculty visibility)
        
        System.runAs(studentUser) {
            // Complete all requirements in irsLocal (Contact parent - Faculty visibility)
            for (reduivy__Individual_Requirement__c irq : irsLocal.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
            }
            update irsLocal.reduivy__Individual_Requirements__r;
        }
        
        // Verify Contact indicator is still false (irsGeneral not complete yet)
        studentContact = queryContact(studentContact.Id);
        System.Assert.areEqual(false, (Boolean) studentContact.get('reduivy__Test_Requirements_Complete_Faculty__c'), 
            'Contact Faculty indicator should be false with one IRS incomplete!');
        
        System.runAs(studentUser) {
            // Complete all requirements in irsGeneral (Contact parent - Faculty visibility)
            for (reduivy__Individual_Requirement__c irq : irsGeneral.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
            }
            update irsGeneral.reduivy__Individual_Requirements__r;
        }
        
        // Verify Contact indicator is now true (both IRS complete)
        studentContact = queryContact(studentContact.Id);
        System.Assert.areEqual(true, (Boolean) studentContact.get('reduivy__Test_Requirements_Complete_Faculty__c'), 
            'Contact Faculty indicator should be true with all Contact IRS complete!');
        
        // Verify IPA indicator is still false (irsApplication not complete yet)
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(false, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Faculty__c'), 
            'IPA Faculty indicator should be false with IPA IRS incomplete!');
        
        System.runAs(studentUser) {
            // Complete all requirements in irsApplication (IPA parent - Admin visibility)
            for (reduivy__Individual_Requirement__c irq : irsApplication.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
            }
            update irsApplication.reduivy__Individual_Requirements__r;
        }
        
        // Verify IPA indicator is now true
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Faculty__c'), 
            'IPA Faculty indicator should be true with all IPA IRS complete!');
        
        // Verify Contact indicator remains true
        studentContact = queryContact(studentContact.Id);
        System.Assert.areEqual(true, (Boolean) studentContact.get('reduivy__Test_Requirements_Complete_Faculty__c'), 
            'Contact Faculty indicator should remain true!');
        
        Test.stopTest();
    }

    /**
     * @description Test multiple parent objects with mixed visibility as student
     */
    @IsTest
    static void testForUpdate_MultipleParentObjects_MixedVisibility_AsStudent() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA() || !CON_Helper.canRunEvaluationTestForRequirementIndicatorInContact()){
            return;
        }

        User studentUser = testFactory.getStudentUser();
        transferIRQOwnership(studentUser.Id);

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Program_Application__c ipa = (reduivy__Individual_Program_Application__c)testData.get('ipa');
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');
        reduivy__Individual_Requirement_Set__c irsGeneral = (reduivy__Individual_Requirement_Set__c)testData.get('irsGeneral');
        reduivy__Individual_Requirement_Set__c irsApplication = (reduivy__Individual_Requirement_Set__c)testData.get('irsApplication');
        
        // Get the contact associated with the IPA
        Contact studentContact = [
            SELECT Id
            FROM Contact
            WHERE Id = :ipa.reduivy__Contact__c
            LIMIT 1
        ];
        
        // Update SRS to point to different objects
        List<reduivy__Study_Requirement_Set__c> srsListToUpdate = [
            SELECT Id, reduivy__Object__c, reduivy__Sample_Record_Code__c,
                reduivy__Completion_Indicator_Admin__c,
                reduivy__Completion_Indicator_Faculty__c,
                reduivy__Completion_Indicator_Student__c
            FROM reduivy__Study_Requirement_Set__c
            WHERE reduivy__Sample_Record_Code__c IN (:SRS_LOCAL)
        ];
        
        for (reduivy__Study_Requirement_Set__c srs : srsListToUpdate) {
            // Change object to Contact
            srs.reduivy__Object__c = CON_Helper.getApiName();
            srs.reduivy__Completion_Indicator_Admin__c = 'reduivy__Test_Requirements_Complete_Admin__c';
            srs.reduivy__Completion_Indicator_Faculty__c = 'reduivy__Test_Requirements_Complete_Faculty__c';
            srs.reduivy__Completion_Indicator_Student__c = 'reduivy__Test_Requirements_Complete_Student__c';
        }
        
        update srsListToUpdate;
        
        // Update IRS to point to Contact for Local and General
        irsLocal.reduivy__Contact__c = studentContact.Id;
        irsGeneral.reduivy__Contact__c = studentContact.Id;
        
        List<reduivy__Individual_Requirement_Set__c> irsToUpdateParent = new List<reduivy__Individual_Requirement_Set__c>{
            irsLocal, irsGeneral
        };
        
        update irsToUpdateParent;

        // List for Contact IRS (irsLocal + irsGeneral)
        List<reduivy__Individual_Requirement__c> contactIRQs = new List<reduivy__Individual_Requirement__c>();

        if (irsLocal.reduivy__Individual_Requirements__r != null) {
            contactIRQs.addAll(irsLocal.reduivy__Individual_Requirements__r);
        }
        if (irsGeneral.reduivy__Individual_Requirements__r != null) {
            contactIRQs.addAll(irsGeneral.reduivy__Individual_Requirements__r);
        }

        // Update Contact IRS requirements
        for (reduivy__Individual_Requirement__c irq : contactIRQs) {
            irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_FACULTY;
        }
        if (!contactIRQs.isEmpty()) {
            update contactIRQs;
        }

        // List for IPA IRS (irsApplication)
        List<reduivy__Individual_Requirement__c> ipaIRQs = new List<reduivy__Individual_Requirement__c>();

        if (irsApplication.reduivy__Individual_Requirements__r != null) {
            ipaIRQs.addAll(irsApplication.reduivy__Individual_Requirements__r);
        }

        // Update IPA IRS requirements
        for (reduivy__Individual_Requirement__c irq : ipaIRQs) {
            irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_STUDENT;
        }
        if (!ipaIRQs.isEmpty()) {
            update ipaIRQs;
        }
        
        System.runAs(studentUser) {
            // Set Contact IRS (irsLocal, irsGeneral) to Faculty visibility and complete them
            for (reduivy__Individual_Requirement__c irq : irsLocal.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
            }
            update irsLocal.reduivy__Individual_Requirements__r;
            
            for (reduivy__Individual_Requirement__c irq : irsGeneral.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
            }
            update irsGeneral.reduivy__Individual_Requirements__r;
        
            // Set IPA IRS (irsApplication) to Student visibility and complete them
            for (reduivy__Individual_Requirement__c irq : irsApplication.reduivy__Individual_Requirements__r) {
                irq.reduivy__Submission_Status__c = IRQ_Helper.SUBMISSION_STATUS_SUBMITTED;
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
            }
            update irsApplication.reduivy__Individual_Requirements__r;
        }
        
        // Verify Contact Faculty indicator is true
        studentContact = queryContact(studentContact.Id);
        System.Assert.areEqual(true, (Boolean) studentContact.get('reduivy__Test_Requirements_Complete_Faculty__c'), 
            'Contact Faculty indicator should be true!');
        System.Assert.areEqual(true, (Boolean) studentContact.get('reduivy__Test_Requirements_Complete_Admin__c'), 
            'Contact Admin indicator should be true!');
        
        // Verify IPA Student indicator is true
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Student__c'), 
            'IPA Student indicator should be true!');
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 
            'IPA Admin indicator should be true!');
        
        Test.stopTest();
    }

    /**
     * @description Test AfterInsert - IRS created with completed requirements should update parent as student
     */
    @IsTest
    static void testForInsert_NewIRSWithCompletedRequirements_UpdatesParent_AsStudent() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA()){
            return;
        }

        User studentUser = testFactory.getStudentUser();
        transferIRQOwnership(studentUser.Id);

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Program_Application__c ipa = (reduivy__Individual_Program_Application__c)testData.get('ipa');
        reduivy__Individual_Requirement_Set__c irsLocal = (reduivy__Individual_Requirement_Set__c)testData.get('irsLocal');
        reduivy__Individual_Requirement_Set__c irsGeneral = (reduivy__Individual_Requirement_Set__c)testData.get('irsGeneral');
        reduivy__Individual_Requirement_Set__c irsApplication = (reduivy__Individual_Requirement_Set__c)testData.get('irsApplication');
        
        System.runAs(studentUser) {
            // Complete all existing IRS requirements
            for (reduivy__Individual_Requirement__c irq : irsGeneral.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsGeneral.reduivy__Individual_Requirements__r;

            for (reduivy__Individual_Requirement__c irq : irsLocal.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsLocal.reduivy__Individual_Requirements__r;

            for (reduivy__Individual_Requirement__c irq : irsApplication.reduivy__Individual_Requirements__r) {
                irq.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;
                irq.reduivy__Requirement_Visibility__c = IRQ_Helper.REQUIREMENT_VISIBILITY_ADMIN;
            }
            update irsApplication.reduivy__Individual_Requirements__r;
        }

        // Verify parent is complete
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(true, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 
            'IPA should be complete before new IRS!');

        // Create a new IRS manually (simulating AfterInsert)
        // Get SRS
        List<reduivy__Study_Requirement_Set__c> srsList = [
            SELECT Id, reduivy__Object__c
            FROM reduivy__Study_Requirement_Set__c
            WHERE reduivy__Sample_Record_Code__c = :SRS_LOCAL
            LIMIT 1
        ];

        // Create new IRS
        reduivy__Individual_Requirement_Set__c newIrs = new reduivy__Individual_Requirement_Set__c(
            reduivy__Study_Requirement_Set__c = srsList[0].Id,
            reduivy__Individual_Program_Application__c = ipa.Id,
            reduivy__Status__c = IRS_Helper.STATUS_ACTIVE,
            reduivy__Total_Requirement__c = 1,
            reduivy__Total_Reviewed__c = 0, // Incomplete
            reduivy__Total_Requirement_Faculty__c = 0,
            reduivy__Total_Requirement_Student__c = 0
        );

        System.runAs(studentUser) {
            insert newIrs;
        }

        // Verify parent indicator is now false (new incomplete IRS added)
        ipa = queryIPA(ipa.Id);
        System.Assert.areEqual(false, (Boolean) ipa.get('reduivy__Test_Requirements_Complete_Admin__c'), 
            'IPA should be incomplete after new incomplete IRS inserted!');

        Test.stopTest();
    }

    /**
     * @description Test error handling when more than 5 different parent objects are being processed as student
     */
    @IsTest
    static void testForUpdate_MoreThan5ParentObjects_ThrowsError_AsStudent() {
        if(!IPA_Helper.canRunEvaluationTestForRequirementIndicatorInIPA()){
            return;
        }
        
        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
        Map<String, Object> testData = setupTestData();
        reduivy__Individual_Program_Application__c ipa = (reduivy__Individual_Program_Application__c)testData.get('ipa');
        
        List<reduivy__Study_Requirement_Set__c> srsListToCreate = new List<reduivy__Study_Requirement_Set__c>();
        
        // Create 6 SRS pointing to different objects
        List<String> parentObjects = new List<String>{
            'Account',
            'Contact', 
            'Opportunity',
            'Lead',
            'Case',
            'Campaign'
        };
        
        for (Integer i = 0; i < 6; i++) {
            reduivy__Study_Requirement_Set__c srs = new reduivy__Study_Requirement_Set__c(
                Name = 'Test SRS ' + i,
                reduivy__Object__c = parentObjects[i],
                reduivy__Sample_Record_Code__c = 'TEST_SRS_' + i,
                reduivy__Completion_Indicator_Admin__c = 'reduivy__Test_Requirements_Complete_Admin__c',
                reduivy__Completion_Indicator_Faculty__c = 'reduivy__Test_Requirements_Complete_Faculty__c',
                reduivy__Completion_Indicator_Student__c = 'reduivy__Test_Requirements_Complete_Student__c',
                reduivy__Status__c = SRS_Helper.STATUS_ACTIVE,
                reduivy__Requirement_Generation_Mode__c = IRS_Helper.REQUIREMENT_GENERATION_MODE_MANUAL
            );
            srsListToCreate.add(srs);
        }
        
        insert srsListToCreate;
        
        // Create 6 IRS records, each pointing to a different SRS (thus 6 different parent objects)
        List<reduivy__Individual_Requirement_Set__c> irsList = new List<reduivy__Individual_Requirement_Set__c>();
        
        for (Integer i = 0; i < 6; i++) {
            reduivy__Individual_Requirement_Set__c irs = new reduivy__Individual_Requirement_Set__c(
                reduivy__Study_Requirement_Set__c = srsListToCreate[i].Id,
                reduivy__Individual_Program_Application__c = ipa.Id,
                reduivy__Status__c = IRS_Helper.STATUS_ACTIVE,
                reduivy__Total_Requirement__c = 1,
                reduivy__Total_Reviewed__c = 0,
                reduivy__Total_Requirement_Faculty__c = 1,
                reduivy__Total_Requirement_Student__c = 1
            );
            irsList.add(irs);
        }
        
        System.runAs(studentUser) {
            try {
                insert irsList;
                System.Assert.fail('Expected Exception for processing more than 5 parent objects');
            } catch (Exception exp) {
                String expectedError = String.format(Label.Too_Many_Parent_Objects_In_Transaction,
                            new List<String>{SRS_Helper.getObjectLabel(), String.join(parentObjects, ',')});
                System.Assert.isTrue(exp.getMessage().contains(expectedError), 
                    'Expected error message about too many parent objects. Actual: ' + exp.getMessage());
            }
        }

        Test.stopTest();
    }

    /**
     * @description Helper method to query IPA with dynamic field access
     */
    static reduivy__Individual_Program_Application__c queryIPA(Id ipaId) {
        String query = 'SELECT Id, ' + 
                       'reduivy__Test_Requirements_Complete_Admin__c' + ', ' + 
                       'reduivy__Test_Requirements_Complete_Faculty__c' + ', ' + 
                       'reduivy__Test_Requirements_Complete_Student__c' + ', ' +
                       'reduivy__Contact__c ' +
                       'FROM reduivy__Individual_Program_Application__c ' +
                       'WHERE Id = :ipaId LIMIT 1';
        
        return Database.query(query);
    }

    /**
     * @description Helper method to query Contact with dynamic field access
     */
    static Contact queryContact(Id contactId) {
        String query = 'SELECT Id, ' + 
                       'reduivy__Test_Requirements_Complete_Admin__c' + ', ' + 
                       'reduivy__Test_Requirements_Complete_Faculty__c' + ', ' + 
                       'reduivy__Test_Requirements_Complete_Student__c' + ' ' +
                       'FROM Contact ' +
                       'WHERE Id = :contactId LIMIT 1';
        
        return Database.query(query);
    }

    /**
     * @description Helper method to query IRS
     */
    static reduivy__Individual_Requirement_Set__c queryIrs(Id irsId) {
        return [
            SELECT Id, Name, reduivy__Status__c, reduivy__Study_Requirement_Set__c,
                   reduivy__Total_Requirement__c, reduivy__Total_Reviewed__c, reduivy__Total_Submitted__c,
                   reduivy__Total_Requirement_Faculty__c, reduivy__Total_Reviewed_Faculty__c, reduivy__Total_Submitted_Faculty__c,
                   reduivy__Total_Requirement_Student__c, reduivy__Total_Reviewed_Student__c, reduivy__Total_Submitted_Student__c,
                   (SELECT Id, Name, reduivy__Status__c, reduivy__Review_Status__c, reduivy__Submission_Status__c,
                           reduivy__Requirement_Visibility__c, OwnerId
                    FROM reduivy__Individual_Requirements__r
                    WHERE reduivy__Status__c = :IRQ_Helper.STATUS_ACTIVE)
            FROM reduivy__Individual_Requirement_Set__c
            WHERE Id = :irsId
            LIMIT 1
        ];
    }

    /**
     * @description Helper method to setup test data
     */
    static Map<String, Object> setupTestData() {
        Map<String, Object> result = new Map<String, Object>();
        User studentUser = testFactory.getStudentUser();

        Id studentUserContactId = studentUser.ContactId;

        // Query IPA using dynamic query to handle field existence
        String ipaQuery = 'SELECT Id, reduivy__Contact__c, ' +
                          'reduivy__Test_Requirements_Complete_Admin__c' + ', ' +
                          'reduivy__Test_Requirements_Complete_Faculty__c' + ', ' +
                          'reduivy__Test_Requirements_Complete_Student__c' + ' ' +
                          'FROM reduivy__Individual_Program_Application__c ' +
                          'WHERE reduivy__Application_Status__c = :IPA_CREATE_IRS_STATUS ' +
                          'AND reduivy__Contact__c = :studentUserContactId ' +
                          'LIMIT 1';
        
        reduivy__Individual_Program_Application__c ipa = Database.query(ipaQuery);
        result.put('ipa', ipa);

        reduivy__Individual_Requirement_Set__c irsLocal;
        reduivy__Individual_Requirement_Set__c irsGeneral;
        reduivy__Individual_Requirement_Set__c irsApplication;

        // Query IRS
        for (reduivy__Individual_Requirement_Set__c irs : [
            SELECT Id, Name, reduivy__Status__c, reduivy__Study_Requirement_Set__c, reduivy__Study_Requirement_Set__r.reduivy__Sample_Record_Code__c,
                   reduivy__Sample_Record_Code__c,
                   reduivy__Total_Requirement__c, reduivy__Total_Reviewed__c, reduivy__Total_Submitted__c,
                   (SELECT Id, Name, reduivy__Status__c, reduivy__Review_Status__c, reduivy__Submission_Status__c,
                           reduivy__Requirement_Visibility__c, OwnerId, reduivy__Study_Requirement__c
                    FROM reduivy__Individual_Requirements__r
                    WHERE reduivy__Status__c = :IRQ_Helper.STATUS_ACTIVE)
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Individual_Program_Application__c = :ipa.Id
        ]) {
            if (irs.reduivy__Study_Requirement_Set__r.reduivy__Sample_Record_Code__c == SRS_LOCAL) {
                irsLocal = irs;
            } else if (irs.reduivy__Study_Requirement_Set__r.reduivy__Sample_Record_Code__c == SRS_GENERAL) {
                irsGeneral = irs;
            } else if (irs.reduivy__Study_Requirement_Set__r.reduivy__Sample_Record_Code__c == SRS_APPLICATION) {
                irsApplication = irs;
            }
        }
        result.put('irsLocal', irsLocal);
        result.put('irsGeneral', irsGeneral);
        result.put('irsApplication', irsApplication);

        // Verify we have the expected data
        System.Assert.isNotNull(ipa, 'IPA should be created by factory!');
        System.Assert.isNotNull(ipa.reduivy__Contact__c, 'IPA\'s contact Id should be populated!');
        System.Assert.isNotNull(irsLocal, 'IRS Local should be created.');
        System.Assert.isNotNull(irsGeneral, 'IRS General should be created.');
        System.Assert.isNotNull(irsApplication, 'IRS Application should be created.');
        System.Assert.isTrue(irsLocal.reduivy__Individual_Requirements__r.size() > 0, 'IRS Local should have at least 1 requirements.');
        System.Assert.isTrue(irsGeneral.reduivy__Individual_Requirements__r.size() > 0, 'IRS General should have at least 1 requirements.');
        System.Assert.isTrue(irsApplication.reduivy__Individual_Requirements__r.size() > 0, 'IRS Application should have at least 1 requirements.');
        
        return result;
    }

    /**
     * @description Helper method to transfer ownership of all IRQs in the org to a given user
     * @param newOwnerId User ID to set as the new owner for all IRQs
     */
    static void transferIRQOwnership(Id newOwnerId) {
        List<reduivy__Individual_Requirement__c> allIrqs = [
            SELECT Id, OwnerId 
            FROM reduivy__Individual_Requirement__c
        ];
        
        if (!allIrqs.isEmpty()) {
            for (reduivy__Individual_Requirement__c irq : allIrqs) {
                irq.OwnerId = newOwnerId;
            }
            update allIrqs;
        }
    }
}