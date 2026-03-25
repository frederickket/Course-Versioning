/**
 * @author      WDCi (XW)
 * @date        July 2025
 * @group       Test
 * @description Test class for IRQ_SetSubmissionStatus_EXE
 * @changehistory
 * ISS-002128 03-07-2025 XW - new class
 */
@IsTest
public inherited sharing class IRQ_SetSubmissionStatus_TEST {

    static Map<String, String> reviewStatusToSubmissionStatusMap = IRQ_Helper.getSubmissionStatusMap();
    static String SRC_IRS = 'SRC_IRS';

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
        	
            testFactory.initFacultyData(USR_Helper.getApiName(), true);
            testFactory.initStudentData(USR_Helper.getApiName(), true);
            

            reduivy__Individual_Requirement_Set__c irs = new reduivy__Individual_Requirement_Set__c(
                reduivy__Sample_Record_Code__c = SRC_IRS,
                OwnerId = testFactory.getStudentUser().Id
            );

            insert irs;

            Test.stopTest();
		}

    }
	
    /**
     * @description Test as admin for inserting ipa with review status = accepted
     */
    @IsTest
    static void testForInsert_Accepted_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        reduivy__Individual_Requirement_Set__c irs = queryIrs();
        reduivy__Individual_Requirement__c irqToInsert = new reduivy__Individual_Requirement__c(
            reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED,
            reduivy__Individual_Requirement_Set__c = irs.Id
        );
        System.runAs(ADMIN_USER){
            insert irqToInsert;
		}

        reduivy__Individual_Requirement__c irqAfter = queryIrq(irqToInsert.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_ACCEPTED, irqAfter.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfter.reduivy__Review_Status__c), irqAfter.reduivy__Submission_Status__c);

        Test.stopTest();
		
    }
	
    /**
     * @description Test as admin for inserting ipa with review status = Conditionally Accepted
     */
    @IsTest
    static void testForInsert_ConditionallyAccepted_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        reduivy__Individual_Requirement_Set__c irs = queryIrs();
        reduivy__Individual_Requirement__c irqToInsert = new reduivy__Individual_Requirement__c(
            reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_CONDITIONALLY_ACCEPTED,
            reduivy__Individual_Requirement_Set__c = irs.Id
        );
        System.runAs(ADMIN_USER){
            insert irqToInsert;
		}

        reduivy__Individual_Requirement__c irqAfter = queryIrq(irqToInsert.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_CONDITIONALLY_ACCEPTED, irqAfter.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfter.reduivy__Review_Status__c), irqAfter.reduivy__Submission_Status__c);

        Test.stopTest();
		
    }
	
    /**
     * @description Test as admin for inserting ipa with review status = Not Accepted
     */
    @IsTest
    static void testForInsert_NotAccepted_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        reduivy__Individual_Requirement_Set__c irs = queryIrs();
        reduivy__Individual_Requirement__c irqToInsert = new reduivy__Individual_Requirement__c(
            reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_NOT_ACCEPTED,
            reduivy__Individual_Requirement_Set__c = irs.Id
        );
        System.runAs(ADMIN_USER){
            insert irqToInsert;
		}

        reduivy__Individual_Requirement__c irqAfter = queryIrq(irqToInsert.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_NOT_ACCEPTED, irqAfter.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfter.reduivy__Review_Status__c), irqAfter.reduivy__Submission_Status__c);

        Test.stopTest();
		
    }
	
    /**
     * @description Test as admin for inserting ipa with review status = Not Required
     */
    @IsTest
    static void testForInsert_NotRequired_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        reduivy__Individual_Requirement_Set__c irs = queryIrs();
        reduivy__Individual_Requirement__c irqToInsert = new reduivy__Individual_Requirement__c(
            reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_NOT_REQUIRED,
            reduivy__Individual_Requirement_Set__c = irs.Id
        );
        System.runAs(ADMIN_USER){
            insert irqToInsert;
		}

        reduivy__Individual_Requirement__c irqAfter = queryIrq(irqToInsert.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_NOT_REQUIRED, irqAfter.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfter.reduivy__Review_Status__c), irqAfter.reduivy__Submission_Status__c);

        Test.stopTest();
		
    }
	
    /**
     * @description Test as admin for inserting ipa with review status = Open
     */
    @IsTest
    static void testForInsert_Open_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        reduivy__Individual_Requirement_Set__c irs = queryIrs();
        reduivy__Individual_Requirement__c irqToInsert = new reduivy__Individual_Requirement__c(
            reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_OPEN,
            reduivy__Individual_Requirement_Set__c = irs.Id
        );
        System.runAs(ADMIN_USER){
            insert irqToInsert;
		}

        reduivy__Individual_Requirement__c irqAfter = queryIrq(irqToInsert.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_OPEN, irqAfter.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfter.reduivy__Review_Status__c), irqAfter.reduivy__Submission_Status__c);

        Test.stopTest();
		
    }
	
    /**
     * @description Test as admin for inserting ipa with review status = Under Review
     */
    @IsTest
    static void testForInsert_UnderReview_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        reduivy__Individual_Requirement_Set__c irs = queryIrs();
        reduivy__Individual_Requirement__c irqToInsert = new reduivy__Individual_Requirement__c(
            reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_UNDER_REVIEW,
            reduivy__Individual_Requirement_Set__c = irs.Id
        );
        System.runAs(ADMIN_USER){
            insert irqToInsert;
		}

        reduivy__Individual_Requirement__c irqAfter = queryIrq(irqToInsert.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_UNDER_REVIEW, irqAfter.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfter.reduivy__Review_Status__c), irqAfter.reduivy__Submission_Status__c);

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for updating ipa with review status from Open to accepted
     */
    @IsTest
    static void testForUpdate_OpenToAccepted_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        reduivy__Individual_Requirement_Set__c irs = queryIrs();
        reduivy__Individual_Requirement__c irqToUpdate = new reduivy__Individual_Requirement__c(
            reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_OPEN,
            reduivy__Individual_Requirement_Set__c = irs.Id
        );
        System.runAs(ADMIN_USER){
            insert irqToUpdate;
		}

        reduivy__Individual_Requirement__c irqAfterInsert = queryIrq(irqToUpdate.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_OPEN, irqAfterInsert.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfterInsert.reduivy__Review_Status__c), irqAfterInsert.reduivy__Submission_Status__c);

        //start test
        irqToUpdate.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;

        System.runAs(ADMIN_USER){
            update irqToUpdate;
		}

        reduivy__Individual_Requirement__c irqAfterUpdate = queryIrq(irqToUpdate.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_ACCEPTED, irqAfterUpdate.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfterUpdate.reduivy__Review_Status__c), irqAfterUpdate.reduivy__Submission_Status__c);

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for updating ipa with review status from Open to Conditionally Accepted
     */
    @IsTest
    static void testForUpdate_OpenToConditionallyAccepted_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        reduivy__Individual_Requirement_Set__c irs = queryIrs();
        reduivy__Individual_Requirement__c irqToUpdate = new reduivy__Individual_Requirement__c(
            reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_OPEN,
            reduivy__Individual_Requirement_Set__c = irs.Id
        );
        System.runAs(ADMIN_USER){
            insert irqToUpdate;
		}

        reduivy__Individual_Requirement__c irqAfterInsert = queryIrq(irqToUpdate.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_OPEN, irqAfterInsert.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfterInsert.reduivy__Review_Status__c), irqAfterInsert.reduivy__Submission_Status__c);

        //start test
        irqToUpdate.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_CONDITIONALLY_ACCEPTED;

        System.runAs(ADMIN_USER){
            update irqToUpdate;
		}

        reduivy__Individual_Requirement__c irqAfterUpdate = queryIrq(irqToUpdate.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_CONDITIONALLY_ACCEPTED, irqAfterUpdate.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfterUpdate.reduivy__Review_Status__c), irqAfterUpdate.reduivy__Submission_Status__c);

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for updating ipa with review status from Open to Not Accepted
     */
    @IsTest
    static void testForUpdate_OpenToNotAccepted_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        reduivy__Individual_Requirement_Set__c irs = queryIrs();
        reduivy__Individual_Requirement__c irqToUpdate = new reduivy__Individual_Requirement__c(
            reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_OPEN,
            reduivy__Individual_Requirement_Set__c = irs.Id
        );
        System.runAs(ADMIN_USER){
            insert irqToUpdate;
		}

        reduivy__Individual_Requirement__c irqAfterInsert = queryIrq(irqToUpdate.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_OPEN, irqAfterInsert.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfterInsert.reduivy__Review_Status__c), irqAfterInsert.reduivy__Submission_Status__c);

        //start test
        irqToUpdate.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_NOT_ACCEPTED;

        System.runAs(ADMIN_USER){
            update irqToUpdate;
		}

        reduivy__Individual_Requirement__c irqAfterUpdate = queryIrq(irqToUpdate.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_NOT_ACCEPTED, irqAfterUpdate.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfterUpdate.reduivy__Review_Status__c), irqAfterUpdate.reduivy__Submission_Status__c);

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for updating ipa with review status from Open to Not Required
     */
    @IsTest
    static void testForUpdate_OpenToNotRequired_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        reduivy__Individual_Requirement_Set__c irs = queryIrs();
        reduivy__Individual_Requirement__c irqToUpdate = new reduivy__Individual_Requirement__c(
            reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_OPEN,
            reduivy__Individual_Requirement_Set__c = irs.Id
        );
        System.runAs(ADMIN_USER){
            insert irqToUpdate;
		}

        reduivy__Individual_Requirement__c irqAfterInsert = queryIrq(irqToUpdate.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_OPEN, irqAfterInsert.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfterInsert.reduivy__Review_Status__c), irqAfterInsert.reduivy__Submission_Status__c);

        //start test
        irqToUpdate.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_NOT_REQUIRED;

        System.runAs(ADMIN_USER){
            update irqToUpdate;
		}

        reduivy__Individual_Requirement__c irqAfterUpdate = queryIrq(irqToUpdate.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_NOT_REQUIRED, irqAfterUpdate.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfterUpdate.reduivy__Review_Status__c), irqAfterUpdate.reduivy__Submission_Status__c);

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for updating ipa with review status from Accepted to Open
     */
    @IsTest
    static void testForUpdate_AcceptedToUnderReview_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        reduivy__Individual_Requirement_Set__c irs = queryIrs();
        reduivy__Individual_Requirement__c irqToUpdate = new reduivy__Individual_Requirement__c(
            reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED,
            reduivy__Individual_Requirement_Set__c = irs.Id
        );
        System.runAs(ADMIN_USER){
            insert irqToUpdate;
		}

        reduivy__Individual_Requirement__c irqAfterInsert = queryIrq(irqToUpdate.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_ACCEPTED, irqAfterInsert.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfterInsert.reduivy__Review_Status__c), irqAfterInsert.reduivy__Submission_Status__c);

        //start test
        irqToUpdate.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_OPEN;

        System.runAs(ADMIN_USER){
            update irqToUpdate;
		}

        reduivy__Individual_Requirement__c irqAfterUpdate = queryIrq(irqToUpdate.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_OPEN, irqAfterUpdate.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfterUpdate.reduivy__Review_Status__c), irqAfterUpdate.reduivy__Submission_Status__c);

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for updating ipa with review status from Open to Under Review
     */
    @IsTest
    static void testForUpdate_OpenToUnderReview_AsAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        reduivy__Individual_Requirement_Set__c irs = queryIrs();
        reduivy__Individual_Requirement__c irqToUpdate = new reduivy__Individual_Requirement__c(
            reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_OPEN,
            reduivy__Individual_Requirement_Set__c = irs.Id
        );
        System.runAs(ADMIN_USER){
            insert irqToUpdate;
		}

        reduivy__Individual_Requirement__c irqAfterInsert = queryIrq(irqToUpdate.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_OPEN, irqAfterInsert.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfterInsert.reduivy__Review_Status__c), irqAfterInsert.reduivy__Submission_Status__c);

        //start test
        irqToUpdate.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_UNDER_REVIEW;

        System.runAs(ADMIN_USER){
            update irqToUpdate;
		}

        reduivy__Individual_Requirement__c irqAfterUpdate = queryIrq(irqToUpdate.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_UNDER_REVIEW, irqAfterUpdate.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfterUpdate.reduivy__Review_Status__c), irqAfterUpdate.reduivy__Submission_Status__c);

        Test.stopTest();
		
    }

    
	
    /**
     * @description Test as faculty for inserting ipa with review status = accepted
     */
    @IsTest
    static void testForInsert_Accepted_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
        reduivy__Individual_Requirement_Set__c irs = queryIrs();
        reduivy__Individual_Requirement__c irqToInsert = new reduivy__Individual_Requirement__c(
            reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED,
            reduivy__Individual_Requirement_Set__c = irs.Id
        );
        System.runAs(FACULTY_USER){
            insert irqToInsert;
		}

        reduivy__Individual_Requirement__c irqAfter = queryIrq(irqToInsert.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_ACCEPTED, irqAfter.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfter.reduivy__Review_Status__c), irqAfter.reduivy__Submission_Status__c);

        Test.stopTest();
		
    }
	
    /**
     * @description Test as faculty for inserting ipa with review status = Conditionally Accepted
     */
    @IsTest
    static void testForInsert_ConditionallyAccepted_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
        reduivy__Individual_Requirement_Set__c irs = queryIrs();
        reduivy__Individual_Requirement__c irqToInsert = new reduivy__Individual_Requirement__c(
            reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_CONDITIONALLY_ACCEPTED,
            reduivy__Individual_Requirement_Set__c = irs.Id
        );
        System.runAs(FACULTY_USER){
            insert irqToInsert;
		}

        reduivy__Individual_Requirement__c irqAfter = queryIrq(irqToInsert.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_CONDITIONALLY_ACCEPTED, irqAfter.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfter.reduivy__Review_Status__c), irqAfter.reduivy__Submission_Status__c);

        Test.stopTest();
		
    }
	
    /**
     * @description Test as faculty for inserting ipa with review status = Not Accepted
     */
    @IsTest
    static void testForInsert_NotAccepted_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
        reduivy__Individual_Requirement_Set__c irs = queryIrs();
        reduivy__Individual_Requirement__c irqToInsert = new reduivy__Individual_Requirement__c(
            reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_NOT_ACCEPTED,
            reduivy__Individual_Requirement_Set__c = irs.Id
        );
        System.runAs(FACULTY_USER){
            insert irqToInsert;
		}

        reduivy__Individual_Requirement__c irqAfter = queryIrq(irqToInsert.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_NOT_ACCEPTED, irqAfter.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfter.reduivy__Review_Status__c), irqAfter.reduivy__Submission_Status__c);

        Test.stopTest();
		
    }
	
    /**
     * @description Test as faculty for inserting ipa with review status = Not Required
     */
    @IsTest
    static void testForInsert_NotRequired_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
        reduivy__Individual_Requirement_Set__c irs = queryIrs();
        reduivy__Individual_Requirement__c irqToInsert = new reduivy__Individual_Requirement__c(
            reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_NOT_REQUIRED,
            reduivy__Individual_Requirement_Set__c = irs.Id
        );
        System.runAs(FACULTY_USER){
            insert irqToInsert;
		}

        reduivy__Individual_Requirement__c irqAfter = queryIrq(irqToInsert.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_NOT_REQUIRED, irqAfter.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfter.reduivy__Review_Status__c), irqAfter.reduivy__Submission_Status__c);

        Test.stopTest();
		
    }
	
    /**
     * @description Test as faculty for inserting ipa with review status = Open
     */
    @IsTest
    static void testForInsert_Open_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
        reduivy__Individual_Requirement_Set__c irs = queryIrs();
        reduivy__Individual_Requirement__c irqToInsert = new reduivy__Individual_Requirement__c(
            reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_OPEN,
            reduivy__Individual_Requirement_Set__c = irs.Id
        );
        System.runAs(FACULTY_USER){
            insert irqToInsert;
		}

        reduivy__Individual_Requirement__c irqAfter = queryIrq(irqToInsert.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_OPEN, irqAfter.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfter.reduivy__Review_Status__c), irqAfter.reduivy__Submission_Status__c);

        Test.stopTest();
		
    }
	
    /**
     * @description Test as faculty for inserting ipa with review status = Under Review
     */
    @IsTest
    static void testForInsert_UnderReview_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
        reduivy__Individual_Requirement_Set__c irs = queryIrs();
        reduivy__Individual_Requirement__c irqToInsert = new reduivy__Individual_Requirement__c(
            reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_UNDER_REVIEW,
            reduivy__Individual_Requirement_Set__c = irs.Id
        );
        System.runAs(FACULTY_USER){
            insert irqToInsert;
		}

        reduivy__Individual_Requirement__c irqAfter = queryIrq(irqToInsert.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_UNDER_REVIEW, irqAfter.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfter.reduivy__Review_Status__c), irqAfter.reduivy__Submission_Status__c);

        Test.stopTest();
		
    }

    /**
     * @description Test as faculty for updating ipa with review status from Open to accepted
     */
    @IsTest
    static void testForUpdate_OpenToAccepted_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
        reduivy__Individual_Requirement_Set__c irs = queryIrs();
        reduivy__Individual_Requirement__c irqToUpdate = new reduivy__Individual_Requirement__c(
            reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_OPEN,
            reduivy__Individual_Requirement_Set__c = irs.Id
        );
        System.runAs(FACULTY_USER){
            insert irqToUpdate;
		}

        reduivy__Individual_Requirement__c irqAfterInsert = queryIrq(irqToUpdate.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_OPEN, irqAfterInsert.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfterInsert.reduivy__Review_Status__c), irqAfterInsert.reduivy__Submission_Status__c);

        //start test
        irqToUpdate.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;

        System.runAs(FACULTY_USER){
            update irqToUpdate;
		}

        reduivy__Individual_Requirement__c irqAfterUpdate = queryIrq(irqToUpdate.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_ACCEPTED, irqAfterUpdate.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfterUpdate.reduivy__Review_Status__c), irqAfterUpdate.reduivy__Submission_Status__c);

        Test.stopTest();
		
    }

    /**
     * @description Test as faculty for updating ipa with review status from Open to Conditionally Accepted
     */
    @IsTest
    static void testForUpdate_OpenToConditionallyAccepted_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
        reduivy__Individual_Requirement_Set__c irs = queryIrs();
        reduivy__Individual_Requirement__c irqToUpdate = new reduivy__Individual_Requirement__c(
            reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_OPEN,
            reduivy__Individual_Requirement_Set__c = irs.Id
        );
        System.runAs(FACULTY_USER){
            insert irqToUpdate;
		}

        reduivy__Individual_Requirement__c irqAfterInsert = queryIrq(irqToUpdate.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_OPEN, irqAfterInsert.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfterInsert.reduivy__Review_Status__c), irqAfterInsert.reduivy__Submission_Status__c);

        //start test
        irqToUpdate.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_CONDITIONALLY_ACCEPTED;

        System.runAs(FACULTY_USER){
            update irqToUpdate;
		}

        reduivy__Individual_Requirement__c irqAfterUpdate = queryIrq(irqToUpdate.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_CONDITIONALLY_ACCEPTED, irqAfterUpdate.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfterUpdate.reduivy__Review_Status__c), irqAfterUpdate.reduivy__Submission_Status__c);

        Test.stopTest();
		
    }

    /**
     * @description Test as faculty for updating ipa with review status from Open to Not Accepted
     */
    @IsTest
    static void testForUpdate_OpenToNotAccepted_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
        reduivy__Individual_Requirement_Set__c irs = queryIrs();
        reduivy__Individual_Requirement__c irqToUpdate = new reduivy__Individual_Requirement__c(
            reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_OPEN,
            reduivy__Individual_Requirement_Set__c = irs.Id
        );
        System.runAs(FACULTY_USER){
            insert irqToUpdate;
		}

        reduivy__Individual_Requirement__c irqAfterInsert = queryIrq(irqToUpdate.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_OPEN, irqAfterInsert.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfterInsert.reduivy__Review_Status__c), irqAfterInsert.reduivy__Submission_Status__c);

        //start test
        irqToUpdate.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_NOT_ACCEPTED;

        System.runAs(FACULTY_USER){
            update irqToUpdate;
		}

        reduivy__Individual_Requirement__c irqAfterUpdate = queryIrq(irqToUpdate.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_NOT_ACCEPTED, irqAfterUpdate.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfterUpdate.reduivy__Review_Status__c), irqAfterUpdate.reduivy__Submission_Status__c);

        Test.stopTest();
		
    }

    /**
     * @description Test as faculty for updating ipa with review status from Open to Not Required
     */
    @IsTest
    static void testForUpdate_OpenToNotRequired_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
        reduivy__Individual_Requirement_Set__c irs = queryIrs();
        reduivy__Individual_Requirement__c irqToUpdate = new reduivy__Individual_Requirement__c(
            reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_OPEN,
            reduivy__Individual_Requirement_Set__c = irs.Id
        );
        System.runAs(FACULTY_USER){
            insert irqToUpdate;
		}

        reduivy__Individual_Requirement__c irqAfterInsert = queryIrq(irqToUpdate.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_OPEN, irqAfterInsert.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfterInsert.reduivy__Review_Status__c), irqAfterInsert.reduivy__Submission_Status__c);

        //start test
        irqToUpdate.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_NOT_REQUIRED;

        System.runAs(FACULTY_USER){
            update irqToUpdate;
		}

        reduivy__Individual_Requirement__c irqAfterUpdate = queryIrq(irqToUpdate.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_NOT_REQUIRED, irqAfterUpdate.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfterUpdate.reduivy__Review_Status__c), irqAfterUpdate.reduivy__Submission_Status__c);

        Test.stopTest();
		
    }

    /**
     * @description Test as faculty for updating ipa with review status from Accepted to Open
     */
    @IsTest
    static void testForUpdate_AcceptedToUnderReview_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
        reduivy__Individual_Requirement_Set__c irs = queryIrs();
        reduivy__Individual_Requirement__c irqToUpdate = new reduivy__Individual_Requirement__c(
            reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED,
            reduivy__Individual_Requirement_Set__c = irs.Id
        );
        System.runAs(FACULTY_USER){
            insert irqToUpdate;
		}

        reduivy__Individual_Requirement__c irqAfterInsert = queryIrq(irqToUpdate.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_ACCEPTED, irqAfterInsert.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfterInsert.reduivy__Review_Status__c), irqAfterInsert.reduivy__Submission_Status__c);

        //start test
        irqToUpdate.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_OPEN;

        System.runAs(FACULTY_USER){
            update irqToUpdate;
		}

        reduivy__Individual_Requirement__c irqAfterUpdate = queryIrq(irqToUpdate.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_OPEN, irqAfterUpdate.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfterUpdate.reduivy__Review_Status__c), irqAfterUpdate.reduivy__Submission_Status__c);

        Test.stopTest();
		
    }

    /**
     * @description Test as faculty for updating ipa with review status from Open to Under Review
     */
    @IsTest
    static void testForUpdate_OpenToUnderReview_AsFaculty() {

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();
        
        reduivy__Individual_Requirement_Set__c irs = queryIrs();
        reduivy__Individual_Requirement__c irqToUpdate = new reduivy__Individual_Requirement__c(
            reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_OPEN,
            reduivy__Individual_Requirement_Set__c = irs.Id
        );
        System.runAs(FACULTY_USER){
            insert irqToUpdate;
		}

        reduivy__Individual_Requirement__c irqAfterInsert = queryIrq(irqToUpdate.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_OPEN, irqAfterInsert.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfterInsert.reduivy__Review_Status__c), irqAfterInsert.reduivy__Submission_Status__c);

        //start test
        irqToUpdate.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_UNDER_REVIEW;

        System.runAs(FACULTY_USER){
            update irqToUpdate;
		}

        reduivy__Individual_Requirement__c irqAfterUpdate = queryIrq(irqToUpdate.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_UNDER_REVIEW, irqAfterUpdate.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfterUpdate.reduivy__Review_Status__c), irqAfterUpdate.reduivy__Submission_Status__c);

        Test.stopTest();
		
    }
    
	
    /**
     * @description Test as student for inserting ipa with review status = accepted
     */
    @IsTest
    static void testForInsert_Accepted_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
        reduivy__Individual_Requirement_Set__c irs = queryIrs();
        reduivy__Individual_Requirement__c irqToInsert = new reduivy__Individual_Requirement__c(
            reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED,
            reduivy__Individual_Requirement_Set__c = irs.Id
        );
        System.runAs(studentUser){
            insert irqToInsert;
		}

        reduivy__Individual_Requirement__c irqAfter = queryIrq(irqToInsert.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_ACCEPTED, irqAfter.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfter.reduivy__Review_Status__c), irqAfter.reduivy__Submission_Status__c);

        Test.stopTest();
		
    }
	
    /**
     * @description Test as student for inserting ipa with review status = Conditionally Accepted
     */
    @IsTest
    static void testForInsert_ConditionallyAccepted_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
        reduivy__Individual_Requirement_Set__c irs = queryIrs();
        reduivy__Individual_Requirement__c irqToInsert = new reduivy__Individual_Requirement__c(
            reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_CONDITIONALLY_ACCEPTED,
            reduivy__Individual_Requirement_Set__c = irs.Id
        );
        System.runAs(studentUser){
            insert irqToInsert;
		}

        reduivy__Individual_Requirement__c irqAfter = queryIrq(irqToInsert.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_CONDITIONALLY_ACCEPTED, irqAfter.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfter.reduivy__Review_Status__c), irqAfter.reduivy__Submission_Status__c);

        Test.stopTest();
		
    }
	
    /**
     * @description Test as student for inserting ipa with review status = Not Accepted
     */
    @IsTest
    static void testForInsert_NotAccepted_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
        reduivy__Individual_Requirement_Set__c irs = queryIrs();
        reduivy__Individual_Requirement__c irqToInsert = new reduivy__Individual_Requirement__c(
            reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_NOT_ACCEPTED,
            reduivy__Individual_Requirement_Set__c = irs.Id
        );
        System.runAs(studentUser){
            insert irqToInsert;
		}

        reduivy__Individual_Requirement__c irqAfter = queryIrq(irqToInsert.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_NOT_ACCEPTED, irqAfter.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfter.reduivy__Review_Status__c), irqAfter.reduivy__Submission_Status__c);

        Test.stopTest();
		
    }
	
    /**
     * @description Test as student for inserting ipa with review status = Not Required
     */
    @IsTest
    static void testForInsert_NotRequired_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
        reduivy__Individual_Requirement_Set__c irs = queryIrs();
        reduivy__Individual_Requirement__c irqToInsert = new reduivy__Individual_Requirement__c(
            reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_NOT_REQUIRED,
            reduivy__Individual_Requirement_Set__c = irs.Id
        );
        System.runAs(studentUser){
            insert irqToInsert;
		}

        reduivy__Individual_Requirement__c irqAfter = queryIrq(irqToInsert.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_NOT_REQUIRED, irqAfter.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfter.reduivy__Review_Status__c), irqAfter.reduivy__Submission_Status__c);

        Test.stopTest();
		
    }
	
    /**
     * @description Test as student for inserting ipa with review status = Open
     */
    @IsTest
    static void testForInsert_Open_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
        reduivy__Individual_Requirement_Set__c irs = queryIrs();
        reduivy__Individual_Requirement__c irqToInsert = new reduivy__Individual_Requirement__c(
            reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_OPEN,
            reduivy__Individual_Requirement_Set__c = irs.Id
        );
        System.runAs(studentUser){
            insert irqToInsert;
		}

        reduivy__Individual_Requirement__c irqAfter = queryIrq(irqToInsert.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_OPEN, irqAfter.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfter.reduivy__Review_Status__c), irqAfter.reduivy__Submission_Status__c);

        Test.stopTest();
		
    }
	
    /**
     * @description Test as student for inserting ipa with review status = Under Review
     */
    @IsTest
    static void testForInsert_UnderReview_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
        reduivy__Individual_Requirement_Set__c irs = queryIrs();
        reduivy__Individual_Requirement__c irqToInsert = new reduivy__Individual_Requirement__c(
            reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_UNDER_REVIEW,
            reduivy__Individual_Requirement_Set__c = irs.Id
        );
        System.runAs(studentUser){
            insert irqToInsert;
		}

        reduivy__Individual_Requirement__c irqAfter = queryIrq(irqToInsert.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_UNDER_REVIEW, irqAfter.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfter.reduivy__Review_Status__c), irqAfter.reduivy__Submission_Status__c);

        Test.stopTest();
		
    }

    /**
     * @description Test as student for updating ipa with review status from Open to accepted
     */
    @IsTest
    static void testForUpdate_OpenToAccepted_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
        reduivy__Individual_Requirement_Set__c irs = queryIrs();
        reduivy__Individual_Requirement__c irqToUpdate = new reduivy__Individual_Requirement__c(
            reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_OPEN,
            reduivy__Individual_Requirement_Set__c = irs.Id
        );
        System.runAs(studentUser){
            insert irqToUpdate;
		}

        reduivy__Individual_Requirement__c irqAfterInsert = queryIrq(irqToUpdate.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_OPEN, irqAfterInsert.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfterInsert.reduivy__Review_Status__c), irqAfterInsert.reduivy__Submission_Status__c);

        //start test
        irqToUpdate.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED;

        System.runAs(studentUser){
            update irqToUpdate;
		}

        reduivy__Individual_Requirement__c irqAfterUpdate = queryIrq(irqToUpdate.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_ACCEPTED, irqAfterUpdate.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfterUpdate.reduivy__Review_Status__c), irqAfterUpdate.reduivy__Submission_Status__c);

        Test.stopTest();
		
    }

    /**
     * @description Test as student for updating ipa with review status from Open to Conditionally Accepted
     */
    @IsTest
    static void testForUpdate_OpenToConditionallyAccepted_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
        reduivy__Individual_Requirement_Set__c irs = queryIrs();
        reduivy__Individual_Requirement__c irqToUpdate = new reduivy__Individual_Requirement__c(
            reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_OPEN,
            reduivy__Individual_Requirement_Set__c = irs.Id
        );
        System.runAs(studentUser){
            insert irqToUpdate;
		}

        reduivy__Individual_Requirement__c irqAfterInsert = queryIrq(irqToUpdate.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_OPEN, irqAfterInsert.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfterInsert.reduivy__Review_Status__c), irqAfterInsert.reduivy__Submission_Status__c);

        //start test
        irqToUpdate.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_CONDITIONALLY_ACCEPTED;

        System.runAs(studentUser){
            update irqToUpdate;
		}

        reduivy__Individual_Requirement__c irqAfterUpdate = queryIrq(irqToUpdate.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_CONDITIONALLY_ACCEPTED, irqAfterUpdate.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfterUpdate.reduivy__Review_Status__c), irqAfterUpdate.reduivy__Submission_Status__c);

        Test.stopTest();
		
    }

    /**
     * @description Test as student for updating ipa with review status from Open to Not Accepted
     */
    @IsTest
    static void testForUpdate_OpenToNotAccepted_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
        reduivy__Individual_Requirement_Set__c irs = queryIrs();
        reduivy__Individual_Requirement__c irqToUpdate = new reduivy__Individual_Requirement__c(
            reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_OPEN,
            reduivy__Individual_Requirement_Set__c = irs.Id
        );
        System.runAs(studentUser){
            insert irqToUpdate;
		}

        reduivy__Individual_Requirement__c irqAfterInsert = queryIrq(irqToUpdate.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_OPEN, irqAfterInsert.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfterInsert.reduivy__Review_Status__c), irqAfterInsert.reduivy__Submission_Status__c);

        //start test
        irqToUpdate.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_NOT_ACCEPTED;

        System.runAs(studentUser){
            update irqToUpdate;
		}

        reduivy__Individual_Requirement__c irqAfterUpdate = queryIrq(irqToUpdate.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_NOT_ACCEPTED, irqAfterUpdate.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfterUpdate.reduivy__Review_Status__c), irqAfterUpdate.reduivy__Submission_Status__c);

        Test.stopTest();
		
    }

    /**
     * @description Test as student for updating ipa with review status from Open to Not Required
     */
    @IsTest
    static void testForUpdate_OpenToNotRequired_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
        reduivy__Individual_Requirement_Set__c irs = queryIrs();
        reduivy__Individual_Requirement__c irqToUpdate = new reduivy__Individual_Requirement__c(
            reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_OPEN,
            reduivy__Individual_Requirement_Set__c = irs.Id
        );
        System.runAs(studentUser){
            insert irqToUpdate;
		}

        reduivy__Individual_Requirement__c irqAfterInsert = queryIrq(irqToUpdate.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_OPEN, irqAfterInsert.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfterInsert.reduivy__Review_Status__c), irqAfterInsert.reduivy__Submission_Status__c);

        //start test
        irqToUpdate.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_NOT_REQUIRED;

        System.runAs(studentUser){
            update irqToUpdate;
		}

        reduivy__Individual_Requirement__c irqAfterUpdate = queryIrq(irqToUpdate.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_NOT_REQUIRED, irqAfterUpdate.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfterUpdate.reduivy__Review_Status__c), irqAfterUpdate.reduivy__Submission_Status__c);

        Test.stopTest();
		
    }

    /**
     * @description Test as student for updating ipa with review status from Accepted to Open
     */
    @IsTest
    static void testForUpdate_AcceptedToUnderReview_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
        reduivy__Individual_Requirement_Set__c irs = queryIrs();
        reduivy__Individual_Requirement__c irqToUpdate = new reduivy__Individual_Requirement__c(
            reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_ACCEPTED,
            reduivy__Individual_Requirement_Set__c = irs.Id
        );
        System.runAs(studentUser){
            insert irqToUpdate;
		}

        reduivy__Individual_Requirement__c irqAfterInsert = queryIrq(irqToUpdate.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_ACCEPTED, irqAfterInsert.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfterInsert.reduivy__Review_Status__c), irqAfterInsert.reduivy__Submission_Status__c);

        //start test
        irqToUpdate.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_OPEN;

        System.runAs(studentUser){
            update irqToUpdate;
		}

        reduivy__Individual_Requirement__c irqAfterUpdate = queryIrq(irqToUpdate.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_OPEN, irqAfterUpdate.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfterUpdate.reduivy__Review_Status__c), irqAfterUpdate.reduivy__Submission_Status__c);

        Test.stopTest();
		
    }

    /**
     * @description Test as student for updating ipa with review status from Open to Under Review
     */
    @IsTest
    static void testForUpdate_OpenToUnderReview_AsStudent() {

        User studentUser = testFactory.getStudentUser();

        Test.startTest();
        
        reduivy__Individual_Requirement_Set__c irs = queryIrs();
        reduivy__Individual_Requirement__c irqToUpdate = new reduivy__Individual_Requirement__c(
            reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_OPEN,
            reduivy__Individual_Requirement_Set__c = irs.Id
        );
        System.runAs(studentUser){
            insert irqToUpdate;
		}

        reduivy__Individual_Requirement__c irqAfterInsert = queryIrq(irqToUpdate.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_OPEN, irqAfterInsert.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfterInsert.reduivy__Review_Status__c), irqAfterInsert.reduivy__Submission_Status__c);

        //start test
        irqToUpdate.reduivy__Review_Status__c = IRQ_Helper.REVIEW_STATUS_UNDER_REVIEW;

        System.runAs(studentUser){
            update irqToUpdate;
		}

        reduivy__Individual_Requirement__c irqAfterUpdate = queryIrq(irqToUpdate.Id);

        System.Assert.areEqual(IRQ_Helper.REVIEW_STATUS_UNDER_REVIEW, irqAfterUpdate.reduivy__Review_Status__c);
        System.Assert.areEqual(reviewStatusToSubmissionStatusMap.get(irqAfterUpdate.reduivy__Review_Status__c), irqAfterUpdate.reduivy__Submission_Status__c);

        Test.stopTest();
		
    }
    
    static reduivy__Individual_Requirement__c queryIrq(Id irqId) {
        return [
            SELECT Id, reduivy__Review_Status__c, reduivy__Submission_Status__c
            FROM reduivy__Individual_Requirement__c
            WHERE Id = :irqId
            LIMIT 1
        ];
    }

    static reduivy__Individual_Requirement_Set__c queryIrs() {
        return [
            SELECT Id
            FROM reduivy__Individual_Requirement_Set__c
            WHERE reduivy__Sample_Record_Code__c = :SRC_IRS
            LIMIT 1
        ];
    }
	
}