/**
 * @author      WDCi (XW)
 * @date        June 2025
 * @group       Test
 * @description Test class for IRQ_Helper
 * @changehistory
 * ISS-002128 18-06-2025 XW - create new class
 */
@IsTest
public inherited sharing class IRQ_Helper_TEST {

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

    }

    /**
     * @description Test object helper method
     */
    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Individual_Requirement__c.getLabel(), IRQ_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Individual_Requirement__c.getLabelPlural(), IRQ_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Individual_Requirement__c.getName(), IRQ_Helper.getApiName());

        Test.stopTest();
        
    }

    /**
     * @description Test get review status configs
     */
    @IsTest
    static void testReviewedStatusConfigsAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        System.runAs(ADMIN_USER){

            List<String> reviewedStatuses = new List<String>();
            for(reduivy__IdvRq_Review_Status_Config__mdt config : IRQ_Helper.getReviewStatusConfig()){
                if(config.reduivy__Reviewed__c) {
                    reviewedStatuses.add(config.reduivy__Review_Status__c);
                }
            }

            System.Assert.areEqual(reviewedStatuses, IRQ_Helper.getReviewedStatuses());
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get review status configs
     */
    @IsTest
    static void testSubmissionStatusConfigsAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();
        
        System.runAs(ADMIN_USER){

            List<String> openStatuses = new List<String>();
            List<String> submittedStatuses = new List<String>();
            List<String> resubmissionStatuses = new List<String>();
            List<String> cancelledStatuses = new List<String>();

            for(reduivy__IdvRq_Submission_Status_Config__mdt config : IRQ_Helper.getSubmissionStatusConfig()){
                if(config.reduivy__Type__c == IRQ_Helper.SUBMISSION_STATUS_TYPE_OPEN) {
                    openStatuses.add(config.reduivy__Submission_Status__c);
                } else if(config.reduivy__Type__c == IRQ_Helper.SUBMISSION_STATUS_TYPE_SUBMITTED) {
                    submittedStatuses.add(config.reduivy__Submission_Status__c);
                } else if(config.reduivy__Type__c == IRQ_Helper.SUBMISSION_STATUS_TYPE_RESUBMISSION_REQUESTED) {
                    resubmissionStatuses.add(config.reduivy__Submission_Status__c);
                } else if(config.reduivy__Type__c == IRQ_Helper.SUBMISSION_STATUS_TYPE_CANCELLED) {
                    cancelledStatuses.add(config.reduivy__Submission_Status__c);
                }
            }

            System.Assert.areEqual(openStatuses, IRQ_Helper.getSubmissionOpenStatuses());
            System.Assert.areEqual(submittedStatuses, IRQ_Helper.getSubmissionSubmittedStatuses());
            System.Assert.areEqual(resubmissionStatuses, IRQ_Helper.getSubmissionResubmissionRequestedStatuses());
            System.Assert.areEqual(cancelledStatuses, IRQ_Helper.getSubmissionCancelledStatuses());
        }

        Test.stopTest();
        
    }
	
}