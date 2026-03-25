/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Test
 * @description Test class for IPE_Helper
 * @changehistory
 * 
 */
@IsTest
public inherited sharing class IPE_Helper_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
    
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
        
        System.Assert.areEqual(SObjectType.reduivy__Individual_Program_Enrollment__c.getLabel(), IPE_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Individual_Program_Enrollment__c.getLabelPlural(), IPE_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Individual_Program_Enrollment__c.getName(), IPE_Helper.getApiName());

        Test.stopTest();
        
    }

    /**
     * @description Test record type id method
     */
    @IsTest
    static void testGetRecordTypes(){
        
        Test.startTest();
        Map<String, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.reduivy__Individual_Program_Enrollment__c.getRecordtypeInfosByDeveloperName();

        System.Assert.areEqual(rtMap.get('Master_Enrollment').getRecordTypeId(), IPE_Helper.getMasterEnrollmentRecordTypeId());
        System.Assert.areEqual(rtMap.get('Master_Enrollment').getName(), IPE_Helper.getMasterEnrollmentRecordTypeLabel());
        System.Assert.areEqual(rtMap.get('Child_Enrollment').getRecordTypeId(), IPE_Helper.getChildEnrollmentRecordTypeId());
        System.Assert.areEqual(rtMap.get('Child_Enrollment').getName(), IPE_Helper.getChildEnrollmentRecordTypeLabel());

        Test.stopTest();
        
    }

    /**
     * @description Test get enrollment status config
     */
    @IsTest
    static void testGetEnrollmentStatusConfig(){
        
        Test.startTest();
        Schema.DescribeFieldResult dfr = Schema.SObjectType.reduivy__Individual_Program_Enrollment__c.fields.reduivy__Enrollment_Status__c;
        List<Schema.PicklistEntry> pleList = dfr.getPicklistValues();

        List<reduivy__IdvPe_Enrollment_Status_Config__mdt> configs = IPE_Helper.getEnrollmentStatusConfig();

        Integer counter = 0;
        for (Schema.PicklistEntry ple : pleList) {
            System.Assert.areEqual(ple.getValue(), configs.get(counter).reduivy__Enrollment_Status__c);

            counter ++;
        }

        Test.stopTest();
        
    }

    /**
     * @description Test get Draft status
     */
    @IsTest
    static void testGetDraftStatus(){
        
        Test.startTest();
        List<String> statuses = IPE_Helper.getDraftStatuses();

        System.Assert.areEqual(false, statuses.isEmpty());
        System.Assert.areEqual(true, statuses.contains('Draft'));

        Test.stopTest();
    }

    /**
     * @description Test get In Progress status
     */
    @IsTest
    static void testGetInProgressStatus(){
        
        Test.startTest();
        List<String> statuses = IPE_Helper.getInProgressStatuses();

        System.Assert.areEqual(false, statuses.isEmpty());
        System.Assert.areEqual(true, statuses.contains('In Progress'));

        Test.stopTest();
    }

    /**
     * @description Test get Completed status
     */
    @IsTest
    static void testGetCompletedStatus(){
        
        Test.startTest();
        List<String> statuses = IPE_Helper.getCompletedStatuses();

        System.Assert.areEqual(false, statuses.isEmpty());
        System.Assert.areEqual(true, statuses.contains('Completed'));

        Test.stopTest();
    }

    /**
     * @description Test get Positive (In Progress and Completed) status
     */
    @IsTest
    static void testGetPositiveStatus(){
        
        Test.startTest();
        List<String> statuses = IPE_Helper.getPositiveStatuses();

        System.Assert.areEqual(false, statuses.isEmpty());
        System.Assert.areEqual(true, statuses.contains('In Progress'));
        System.Assert.areEqual(true, statuses.contains('Completed'));

        Test.stopTest();
    }
	
}