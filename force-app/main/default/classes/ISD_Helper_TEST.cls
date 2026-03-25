/**
 * @author      WDCi (XW)
 * @date        Aug 2025
 * @group       Test
 * @description Test class for ISD_Helper
 * @changehistory
 * 
 */
@IsTest
public inherited sharing class ISD_Helper_TEST {

    /**
     * @description Test object helper method
     */
    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Individual_Score_Detail__c.getLabel(), ISD_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Individual_Score_Detail__c.getLabelPlural(), ISD_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Individual_Score_Detail__c.getName(), ISD_Helper.getApiName());

        Test.stopTest();
        
    }
	
}