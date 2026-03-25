/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Test
 * @description Test class for IEN_Helper
 * @changehistory
 * ISS-002448 07-05-2025 XiRouh - Added test method for getIncreaseAttemptNumberStatuses()
 * ISS-002486 10-06-2025 XiRouh - Added testGetCompletedPassStatus(), testGetCompletedFailStatus()
 * ISS-002580 08-08-2025 XiRouh - Added testGetIncludeInFeeStatuses()
 */
@IsTest
public inherited sharing class IEN_Helper_TEST {

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
        
        System.Assert.areEqual(SObjectType.reduivy__Individual_Enrollment__c.getLabel(), IEN_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Individual_Enrollment__c.getLabelPlural(), IEN_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Individual_Enrollment__c.getName(), IEN_Helper.getApiName());

        Test.stopTest();
        
    }

    /**
     * @description Test record type id method
     */
    @IsTest
    static void testGetRecordTypes(){
        
        Test.startTest();
        Map<String, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.reduivy__Individual_Enrollment__c.getRecordtypeInfosByDeveloperName();

        System.Assert.areEqual(rtMap.get('Student').getRecordTypeId(), IEN_Helper.getStudentRecordTypeId());
        System.Assert.areEqual(rtMap.get('Student').getName(), IEN_Helper.getStudentRecordTypeLabel());
        System.Assert.areEqual(rtMap.get('Faculty').getRecordTypeId(), IEN_Helper.getFacultyRecordTypeId());
        System.Assert.areEqual(rtMap.get('Faculty').getName(), IEN_Helper.getFacultyRecordTypeLabel());

        Test.stopTest();
        
    }

    /**
     * @description Test get enrollment status config
     */
    @IsTest
    static void testGetEnrollmentStatusConfig(){
        
        Test.startTest();
        Schema.DescribeFieldResult dfr = Schema.SObjectType.reduivy__Individual_Enrollment__c.fields.reduivy__Enrollment_Status__c;
        List<Schema.PicklistEntry> pleList = dfr.getPicklistValues();

        List<reduivy__IdvEn_Enrollment_Status_Config__mdt> configs = IEN_Helper.getEnrollmentStatusConfig();
        Set<String> configsEnrollmentStatuses = new Set<String>();

        for (reduivy__IdvEn_Enrollment_Status_Config__mdt config : configs) {
            configsEnrollmentStatuses.add(config.reduivy__Enrollment_Status__c);
        }

        for (Schema.PicklistEntry ple : pleList) {
            System.Assert.isTrue(configsEnrollmentStatuses.contains(ple.getValue()));
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get enrollment status config
     */
    @IsTest
    static void testGetGradeResultConfig(){
        
        Test.startTest();
        Schema.DescribeFieldResult dfr = Schema.SObjectType.reduivy__Individual_Enrollment__c.fields.reduivy__Grade_Result__c;
        List<Schema.PicklistEntry> pleList = dfr.getPicklistValues();

        List<reduivy__Grade_Result_Config__mdt> configs = IEN_Helper.getGradeResultConfig();

        Integer counter = 0;
        for (Schema.PicklistEntry ple : pleList) {
            System.Assert.areEqual(ple.getValue(), configs.get(counter).reduivy__Grade_Result__c);
            
            counter ++;
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get Open status
     */
    @IsTest
    static void testGetOpenStatus(){
        
        Test.startTest();
        List<String> statuses = IEN_Helper.getOpenStatuses();

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
        List<String> statuses = IEN_Helper.getEnrollmentRequestedStatuses();

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
        List<String> statuses = IEN_Helper.getInProgressStatuses();

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
        List<String> statuses = IEN_Helper.getCompletedStatuses();

        System.Assert.areEqual(false, statuses.isEmpty());
        System.Assert.areEqual(true, statuses.contains('Completed'));
        System.Assert.areEqual(true, statuses.contains('Completed Fail'));

        Test.stopTest();
    }

    /**
     * @description Test get Completed pass status
     */
    @IsTest
    static void testGetCompletedPassStatus(){
        
        Test.startTest();
        List<String> statuses = IEN_Helper.getCompletedPassStatuses();

        System.Assert.areEqual(false, statuses.isEmpty());
        System.Assert.areEqual(true, statuses.contains('Completed'));
        System.Assert.areEqual(false, statuses.contains('Completed Fail'));

        Test.stopTest();
    }

    /**
     * @description Test get Completed fail status
     */
    @IsTest
    static void testGetCompletedFailStatus(){
        
        Test.startTest();
        List<String> statuses = IEN_Helper.getCompletedFailStatuses();

        System.Assert.areEqual(false, statuses.isEmpty());
        System.Assert.areEqual(false, statuses.contains('Completed'));
        System.Assert.areEqual(true, statuses.contains('Completed Fail'));

        Test.stopTest();
    }

    /**
     * @description Test get Waitlisted status
     */
    @IsTest
    static void testGetWaitlistedStatus(){
        
        Test.startTest();
        List<String> statuses = IEN_Helper.getWaitlistedStatuses();

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
        List<String> statuses = IEN_Helper.getDroppedStatuses();

        System.Assert.areEqual(false, statuses.isEmpty());
        System.Assert.areEqual(true, statuses.contains('Dropped'));

        Test.stopTest();
    }

    /**
     * @description Test get Withdrawal Requested status
     */
    @IsTest
    static void testGetWithdrawalRequestedStatus(){
        
        Test.startTest();
        List<String> statuses = IEN_Helper.getWithdrawalRequestedStatuses();

        System.Assert.areEqual(false, statuses.isEmpty());
        System.Assert.areEqual(true, statuses.contains('Withdrawal Requested'));

        Test.stopTest();
    }

    /**
     * @description Test get withdrawn status
     */
    @IsTest
    static void testGetWithdrawnStatus(){
        
        Test.startTest();
        List<String> statuses = IEN_Helper.getWithdrawnStatuses();

        System.Assert.areEqual(false, statuses.isEmpty());
        System.Assert.areEqual(true, statuses.contains('Withdrawn'));

        Test.stopTest();
    }

    /**
     * @description Test get Non Enrollable status
     */
    @IsTest
    static void testGetNonEnrollableStatus(){
        
        Test.startTest();
        List<String> statuses = IEN_Helper.getNonEnrollableStatuses();

        System.Assert.areEqual(false, statuses.isEmpty());
        System.Assert.areEqual(true, statuses.contains('Enrolled'));
        System.Assert.areEqual(true, statuses.contains('Withdrawal Requested'));
        System.Assert.areEqual(true, statuses.contains('Completed'));

        Test.stopTest();
    }
	
    /**
     * @description Test get pass statuses from grade result
     */
    @IsTest
    static void testGetGradeResultPassStatuses(){
        
        Test.startTest();
        List<String> statuses = IEN_Helper.getGradeResultPassStatuses();

        System.Assert.areEqual(false, statuses.isEmpty());
        System.Assert.areEqual(true, statuses.contains('Pass'));

        Test.stopTest();
    }

    /**
     * @description Test get fail statuses from grade result
     */
    @IsTest
    static void testGetGradeResultFailStatuses(){
        
        Test.startTest();
        List<String> statuses = IEN_Helper.getGradeResultFailStatuses();

        System.Assert.areEqual(false, statuses.isEmpty());
        System.Assert.areEqual(true, statuses.contains('Fail'));

        Test.stopTest();
    }

    /**
     * @description Test get RPL Grade Result status
     */
    @IsTest
    static void testGetRplGradeResult(){
        
        Test.startTest();
        List<String> statuses = IEN_Helper.getGradeResultRplStatuses();

        System.Assert.areEqual(false, statuses.isEmpty());
        System.Assert.areEqual(true, statuses.contains('RPL'));

        Test.stopTest();
    }

    /**
     * @description Test get Credit Transfer Grade Result status
     */
    @IsTest
    static void testGetCreditTransferGradeResult(){
        
        Test.startTest();
        List<String> statuses = IEN_Helper.getGradeResultCreditTransferStatuses();

        System.Assert.areEqual(false, statuses.isEmpty());
        System.Assert.areEqual(true, statuses.contains('Credit Transfer'));

        Test.stopTest();
    }

    /**
     * @description Test get Waive Grade Result status
     */
    @IsTest
    static void testGetWaiveGradeResult(){
        
        Test.startTest();
        List<String> statuses = IEN_Helper.getGradeResultWaiveStatuses();

        System.Assert.areEqual(false, statuses.isEmpty());
        System.Assert.areEqual(true, statuses.contains('Waive'));

        Test.stopTest();
    }

    /**
     * @description Test get By Pass Grade Result status
     */
    @IsTest
    static void testGetByPassGradeResult(){
        
        Test.startTest();
        List<String> statuses = IEN_Helper.getGradeResultBypassStatuses();

        System.Assert.areEqual(false, statuses.isEmpty());
        System.Assert.areEqual(true, statuses.contains('RPL'));
        System.Assert.areEqual(true, statuses.contains('Credit Transfer'));
        System.Assert.areEqual(true, statuses.contains('Waive'));

        Test.stopTest();
    }

    /**
     * @description Test get Increase Attmpt Number Statuses
     */
    @IsTest
    static void testGetIncreaseAttemptNumberStatuses(){
        
        Test.startTest();
        List<String> statuses = IEN_Helper.getIncreaseAttemptNumberStatuses();

        System.Assert.areEqual(false, statuses.isEmpty());
        System.Assert.areEqual(true, statuses.contains('Completed'));

        Test.stopTest();
    }

    /**
     * @description Test get Include In Fee Statuses
     */
    @IsTest
    static void testGetIncludeInFeeStatuses(){
        
        Test.startTest();
        List<String> statuses = IEN_Helper.getIncludeInFeeStatuses();

        System.Assert.areEqual(false, statuses.isEmpty());
        System.Assert.areEqual(true, statuses.contains('Completed'));
        System.Assert.areEqual(true, statuses.contains('Completed Fail'));
        System.Assert.areEqual(true, statuses.contains('Enrolled'));
        System.Assert.areEqual(true, statuses.contains('Withdrawal Requested'));
        System.Assert.areEqual(true, statuses.contains('Withdrawn With Penalty'));

        Test.stopTest();
    }
}