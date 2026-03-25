/**
 * @author      WDCi (Lean)
 * @date        Dec 2023
 * @group       Test
 * @description Test class for IGI_Helper
 * @changehistory
 * ISS-001918 29-08-2024 CM - Added testGetStatuses()
 */
@IsTest
public inherited sharing class IGI_Helper_TEST {
    
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
        
        System.Assert.areEqual(SObjectType.reduivy__Individual_Grade_Item__c.getLabel(), IGI_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Individual_Grade_Item__c.getLabelPlural(), IGI_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Individual_Grade_Item__c.getName(), IGI_Helper.getApiName());

        Test.stopTest();
        
    }

    /**
     * @description Test get statuses
     */
    @IsTest
    static void testGetStatuses(){
        
        Test.startTest();
        Schema.DescribeFieldResult dfr = Schema.SObjectType.reduivy__Individual_Grade_Item__c.fields.reduivy__Status__c;
        List<Schema.PicklistEntry> pleList = dfr.getPicklistValues();
        //getStatuses() will only return active values, so we need to filter our checking list.
        List<Schema.PicklistEntry> activePleList = new List<Schema.PicklistEntry>();
        for (Schema.PicklistEntry ple : pleList){
            if (ple.isActive()){
                activePleList.add(ple);
            }
        }

        List<Schema.PicklistEntry> igiStatuses = IGI_Helper.getStatuses();

        Integer counter = 0;
        for (Schema.PicklistEntry ple : activePleList) {
            System.Assert.areEqual(ple.getValue(), igiStatuses.get(counter).getValue());

            counter ++;
        }

        Test.stopTest();
        
    }
}