/**
 * @author      WDCi (Lean)
 * @date        July 2023
 * @group       Test
 * @description Test class for SOF_Helper
 * @changehistory
 */
@IsTest
public inherited sharing class SOF_Helper_TEST {

    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Study_Offering__c.getLabel(), SOF_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Offering__c.getLabelPlural(), SOF_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Offering__c.getName(), SOF_Helper.getApiName());

        Test.stopTest();
        
    }

    /**
     * @description Test get status config
     */
    @IsTest
    static void testGetStatusConfig(){
        
        Test.startTest();
        Schema.DescribeFieldResult dfr = Schema.SObjectType.reduivy__Study_Offering__c.fields.reduivy__Status__c;
        List<Schema.PicklistEntry> pleList = dfr.getPicklistValues();

        List<reduivy__Study_Offering_Status_Config__mdt> configs = SOF_Helper.getStatusConfig();

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
        List<String> statuses = SOF_Helper.getNotStartedStatuses();

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
        List<String> statuses = SOF_Helper.getPreEnrollmentOpenedStatuses();

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
        List<String> statuses = SOF_Helper.getEnrollmentOpenedStatuses();

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
        List<String> statuses = SOF_Helper.getEnrollmentClosedStatuses();

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
        List<String> statuses = SOF_Helper.getRunningStatuses();

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
        List<String> statuses = SOF_Helper.getCompletedStatuses();

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
        List<String> statuses = SOF_Helper.getCancelledStatuses();

        System.Assert.areEqual(false, statuses.isEmpty());
        System.Assert.areEqual(true, statuses.contains('Cancelled'));

        Test.stopTest();
    }

    /**
     * @description Test get Positive (Not started, Pre-enrollment Opened, Enrollment Opened, Enrollment Closed, Running (Enrollment Opened), Running) status
     */
    @IsTest
    static void testGetPositiveStatus(){
        
        Test.startTest();
        List<String> statuses = SOF_Helper.getPositiveStatuses();

        System.Assert.areEqual(false, statuses.isEmpty());
        System.Assert.areEqual(true, statuses.contains('Not Started'));
        System.Assert.areEqual(true, statuses.contains('Pre-enrollment Opened'));
        System.Assert.areEqual(true, statuses.contains('Enrollment Opened'));
        System.Assert.areEqual(true, statuses.contains('Enrollment Closed'));
        System.Assert.areEqual(true, statuses.contains('Running (Enrollment Opened)'));
        System.Assert.areEqual(true, statuses.contains('Running'));

        Test.stopTest();
    }
}