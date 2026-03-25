/**
 * @author      WDCi (Lean)
 * @date        April 2023
 * @group       Test
 * @description Test class for ISN_Helper
 * @changehistory
 * 
 */
@IsTest
public inherited sharing class ISN_Helper_TEST {

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
        
        System.Assert.areEqual(SObjectType.reduivy__Individual_Session_Enrollment__c.getLabel(), ISN_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Individual_Session_Enrollment__c.getLabelPlural(), ISN_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Individual_Session_Enrollment__c.getName(), ISN_Helper.getApiName());

        Test.stopTest();
        
    }

    /**
     * @description Test record type id method
     */
    @IsTest
    static void testGetRecordTypes(){
        
        Test.startTest();
        Map<String, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.reduivy__Individual_Session_Enrollment__c.getRecordtypeInfosByDeveloperName();

        System.Assert.areEqual(rtMap.get('Student').getRecordTypeId(), ISN_Helper.getStudentRecordTypeId());
        System.Assert.areEqual(rtMap.get('Student').getName(), ISN_Helper.getStudentRecordTypeLabel());
        System.Assert.areEqual(rtMap.get('Faculty').getRecordTypeId(), ISN_Helper.getFacultyRecordTypeId());
        System.Assert.areEqual(rtMap.get('Faculty').getName(), ISN_Helper.getFacultyRecordTypeLabel());

        Test.stopTest();
        
    }

    /**
     * @description Test get enrollment status config
     */
    @IsTest
    static void testGetEnrollmentStatusConfig(){
        
        Test.startTest();
        Schema.DescribeFieldResult dfr = Schema.SObjectType.reduivy__Individual_Session_Enrollment__c.fields.reduivy__Enrollment_Status__c;
        List<Schema.PicklistEntry> pleList = dfr.getPicklistValues();

        List<reduivy__IdvSn_Enrollment_Status_Config__mdt> configs = ISN_Helper.getEnrollmentStatusConfig();
        Set<String> configsEnrollmentStatuses = new Set<String>();

        for (reduivy__IdvSn_Enrollment_Status_Config__mdt config : configs) {
            configsEnrollmentStatuses.add(config.reduivy__Enrollment_Status__c);
        }

        for (Schema.PicklistEntry ple : pleList) {
            System.Assert.isTrue(configsEnrollmentStatuses.contains(ple.getValue()));
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get Open status
     */
    @IsTest
    static void testGetOpenStatus(){
        
        Test.startTest();
        List<String> statuses = ISN_Helper.getOpenStatuses();

        System.Assert.areEqual(false, statuses.isEmpty());
        System.Assert.areEqual(true, statuses.contains('Not Started'));

        Test.stopTest();
    }

    /**
     * @description Test get Enrollment Requested status
     */
    @IsTest
    static void testGetEnrollmentRequestedStatus(){
        
        Test.startTest();
        List<String> statuses = ISN_Helper.getEnrollmentRequestedStatuses();

        System.Assert.areEqual(false, statuses.isEmpty());
        System.Assert.areEqual(true, statuses.contains('Enrollment Requested'));

        Test.stopTest();
    }

    /**
     * @description Test get In Progress status
     */
    @IsTest
    static void testGetInProgressStatus(){
        
        Test.startTest();
        List<String> statuses = ISN_Helper.getInProgressStatuses();

        System.Assert.areEqual(false, statuses.isEmpty());
        System.Assert.areEqual(true, statuses.contains('Enrolled'));

        Test.stopTest();
    }

    /**
     * @description Test get Completed status
     */
    @IsTest
    static void testGetCompletedStatus(){
        
        Test.startTest();
        List<String> statuses = ISN_Helper.getCompletedStatuses();

        System.Assert.areEqual(false, statuses.isEmpty());
        System.Assert.areEqual(true, statuses.contains('Completed'));

        Test.stopTest();
    }

    /**
     * @description Test get Waitlisted status
     */
    @IsTest
    static void testGetWaitlistedStatus(){
        
        Test.startTest();
        List<String> statuses = ISN_Helper.getWaitlistedStatuses();

        System.Assert.areEqual(false, statuses.isEmpty());
        System.Assert.areEqual(true, statuses.contains('Waitlisted'));

        Test.stopTest();
    }

    /**
     * @description Test get Dropped status
     */
    @IsTest
    static void testGetDroppedStatus(){
        
        Test.startTest();
        List<String> statuses = ISN_Helper.getDroppedStatuses();

        System.Assert.areEqual(false, statuses.isEmpty());
        System.Assert.areEqual(true, statuses.contains('Dropped'));

        Test.stopTest();
    }

    /**
     * @description Test get withdrawn status
     */
    @IsTest
    static void testGetWithdrawnStatus(){
        
        Test.startTest();
        List<String> statuses = ISN_Helper.getWithdrawnStatuses();

        System.Assert.areEqual(false, statuses.isEmpty());
        System.Assert.areEqual(true, statuses.contains('Withdrawn'));

        Test.stopTest();
    }
	
}