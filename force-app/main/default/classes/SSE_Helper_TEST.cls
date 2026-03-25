/**
 * @author      WDCi (Lean)
 * @date        April 2023
 * @group       Test
 * @description Test class for SSE_Helper
 * @changehistory
 * ISS-002050 17-09-2024 Sueanne - added test for status methods
 */
@IsTest
public inherited sharing class SSE_Helper_TEST {

    /**
     * @description Test object helper method
     */
    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Study_Session__c.getLabel(), SSE_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Session__c.getLabelPlural(), SSE_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Session__c.getName(), SSE_Helper.getApiName());

        Test.stopTest();
        
    }

    /**
     * @description Test get status config
     */
    @IsTest
    static void testGetStatusConfig(){
        
        Test.startTest();
        Schema.DescribeFieldResult dfr = Schema.SObjectType.reduivy__Study_Session__c.fields.reduivy__Status__c;
        List<Schema.PicklistEntry> pleList = dfr.getPicklistValues();

        List<reduivy__Study_Session_Status_Config__mdt> configs = SSE_Helper.getStatusConfig();

        Integer counter = 0;
        for (Schema.PicklistEntry ple : pleList) {
            System.Assert.areEqual(ple.getValue(), configs.get(counter).reduivy__Status__c);

            counter ++;
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get Not Started status
     */
    @IsTest
    static void testGetNotStartedStatus(){
        
        Test.startTest();
        List<String> statuses = SSE_Helper.getNotStartedStatuses();

        System.Assert.areEqual(false, statuses.isEmpty());
        System.Assert.areEqual(true, statuses.contains('Not Started'));

        Test.stopTest();
    }

    /**
     * @description Test get Pre-enrollment Opened status
     */
    @IsTest
    static void testGetPreEnrollmentOpenedStatus(){
        
        Test.startTest();
        List<String> statuses = SSE_Helper.getPreEnrollmentOpenedStatuses();

        System.Assert.areEqual(false, statuses.isEmpty());
        System.Assert.areEqual(true, statuses.contains('Pre-enrollment Opened'));

        Test.stopTest();
    }

    /**
     * @description Test get Enrollment Opened status
     */
    @IsTest
    static void testGetEnrollmentOpenedStatus(){
        
        Test.startTest();
        List<String> statuses = SSE_Helper.getEnrollmentOpenedStatuses();

        System.Assert.areEqual(false, statuses.isEmpty());
        System.Assert.areEqual(true, statuses.contains('Enrollment Opened'));
        System.Assert.areEqual(true, statuses.contains('Running (Enrollment Opened)'));

        Test.stopTest();
    }

    /**
     * @description Test get Enrollment Closed status
     */
    @IsTest
    static void testGetEnrollmentClosedStatus(){
        
        Test.startTest();
        List<String> statuses = SSE_Helper.getEnrollmentClosedStatuses();

        System.Assert.areEqual(false, statuses.isEmpty());
        System.Assert.areEqual(true, statuses.contains('Enrollment Closed'));

        Test.stopTest();
    }

    /**
     * @description Test get Running status
     */
    @IsTest
    static void testGetRunningStatus(){
        
        Test.startTest();
        List<String> statuses = SSE_Helper.getRunningStatuses();

        System.Assert.areEqual(false, statuses.isEmpty());
        System.Assert.areEqual(true, statuses.contains('Running'));
        System.Assert.areEqual(true, statuses.contains('Running (Enrollment Opened)'));

        Test.stopTest();
    }

    /**
     * @description Test get Completed status
     */
    @IsTest
    static void testGetCompletedStatus(){
        
        Test.startTest();
        List<String> statuses = SSE_Helper.getCompletedStatuses();

        System.Assert.areEqual(false, statuses.isEmpty());
        System.Assert.areEqual(true, statuses.contains('Completed'));

        Test.stopTest();
    }

    /**
     * @description Test get Cancelled status
     */
    @IsTest
    static void testGetCancelledStatus(){
        
        Test.startTest();
        List<String> statuses = SSE_Helper.getCancelledStatuses();

        System.Assert.areEqual(false, statuses.isEmpty());
        System.Assert.areEqual(true, statuses.contains('Cancelled'));

        Test.stopTest();
    }
	
}