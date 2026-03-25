/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Test
 * @description Test class for CTA_Helper
 * @changehistory
 * 
 */
@IsTest
public inherited sharing class CTA_Helper_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
    
	@TestSetup
    static void makeData(){
        
    }

    /**
     * @description Test object helper method
     */
    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Credit_Transfer_Application__c.getLabel(), CTA_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Credit_Transfer_Application__c.getLabelPlural(), CTA_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Credit_Transfer_Application__c.getName(), CTA_Helper.getApiName());

        Test.stopTest();
        
    }

    /**
     * @description Test get status config
     */
    @IsTest
    static void testGetStatusConfig(){
        
        Test.startTest();
        Schema.DescribeFieldResult dfr = Schema.SObjectType.reduivy__Credit_Transfer_Application__c.fields.reduivy__Status__c;
        List<Schema.PicklistEntry> pleList = dfr.getPicklistValues();

        List<reduivy__Credit_Transfer_App_Status_Config__mdt> configs = CTA_Helper.getStatusConfig();

        Integer counter = 0;
        for (Schema.PicklistEntry ple : pleList) {
            System.Assert.areEqual(ple.getValue(), configs.get(counter).reduivy__Status__c);

            counter ++;
        }

        System.Assert.areEqual(1, CTA_Helper.getDraftStatuses().size());
        System.Assert.isTrue(CTA_Helper.getDraftStatuses().contains('Draft'));

        System.Assert.areEqual(1, CTA_Helper.getSubmittedStatuses().size());
        System.Assert.isTrue(CTA_Helper.getSubmittedStatuses().contains('Submitted'));

        System.Assert.areEqual(1, CTA_Helper.getReviewStatuses().size());
        System.Assert.isTrue(CTA_Helper.getReviewStatuses().contains('Reviewing'));

        System.Assert.areEqual(1, CTA_Helper.getApprovedStatuses().size());
        System.Assert.isTrue(CTA_Helper.getApprovedStatuses().contains('Approved'));

        System.Assert.areEqual(1, CTA_Helper.getRejectedStatuses().size());
        System.Assert.isTrue(CTA_Helper.getRejectedStatuses().contains('Rejected'));

        System.Assert.areEqual(2, CTA_Helper.getCancelledStatuses().size());
        System.Assert.isTrue(CTA_Helper.getCancelledStatuses().contains('Cancelled'));
        System.Assert.isTrue(CTA_Helper.getCancelledStatuses().contains('Expired'));
        Test.stopTest();
        
    }

    /**
     * @description Test get status config performance test with 100 times access
     */
    @IsTest
    static void testGetStatusConfigPerformanceTest(){
        
        Test.startTest();
        Schema.DescribeFieldResult dfr = Schema.SObjectType.reduivy__Credit_Transfer_Application__c.fields.reduivy__Status__c;
        List<Schema.PicklistEntry> pleList = dfr.getPicklistValues();

        List<reduivy__Credit_Transfer_App_Status_Config__mdt> configs = CTA_Helper.getStatusConfig();

        Integer counter = 0;
        for (Schema.PicklistEntry ple : pleList) {
            System.Assert.areEqual(ple.getValue(), configs.get(counter).reduivy__Status__c);

            counter ++;
        }

        Integer startCpu = Limits.getCpuTime();

        for (Integer i = 0; i < 100; i ++) {
            System.Assert.areEqual(1, CTA_Helper.getDraftStatuses().size());
            System.Assert.isTrue(CTA_Helper.getDraftStatuses().contains('Draft'));

            System.Assert.areEqual(1, CTA_Helper.getSubmittedStatuses().size());
            System.Assert.isTrue(CTA_Helper.getSubmittedStatuses().contains('Submitted'));

            System.Assert.areEqual(1, CTA_Helper.getReviewStatuses().size());
            System.Assert.isTrue(CTA_Helper.getReviewStatuses().contains('Reviewing'));

            System.Assert.areEqual(1, CTA_Helper.getApprovedStatuses().size());
            System.Assert.isTrue(CTA_Helper.getApprovedStatuses().contains('Approved'));

            System.Assert.areEqual(1, CTA_Helper.getRejectedStatuses().size());
            System.Assert.isTrue(CTA_Helper.getRejectedStatuses().contains('Rejected'));

            System.Assert.areEqual(2, CTA_Helper.getCancelledStatuses().size());
            System.Assert.isTrue(CTA_Helper.getCancelledStatuses().contains('Cancelled'));
            System.Assert.isTrue(CTA_Helper.getCancelledStatuses().contains('Expired'));
        }
        
        Integer endCpu = Limits.getCpuTime();
        Integer consumedCpu = endCpu - startCpu;
        REDU_Logging_UTIL.debug('testGetStatusConfigPerformanceTest', consumedCpu);

        System.Assert.isTrue(consumedCpu < 500, 'The Apex CPU time consumed is too much: ' + consumedCpu);

        Test.stopTest();
        
    }
	
}