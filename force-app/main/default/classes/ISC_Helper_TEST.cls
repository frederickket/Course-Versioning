/**
 * @author      WDCi (XW)
 * @date        Aug 2025
 * @group       Test
 * @description Test class for ISC_Helper
 * @changehistory
 * 
 */
@IsTest
public inherited sharing class ISC_Helper_TEST {

    /**
     * @description Test object helper method
     */
    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Individual_Score__c.getLabel(), ISC_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Individual_Score__c.getLabelPlural(), ISC_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Individual_Score__c.getName(), ISC_Helper.getApiName());

        Test.stopTest();
        
    }
	
}