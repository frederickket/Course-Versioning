/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Test
 * @description Test class for USR_Helper
 * @changehistory
 */
@IsTest
public inherited sharing class USR_Helper_TEST {

    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.User.getLabel(), USR_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.User.getLabelPlural(), USR_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.User.getName(), USR_Helper.getApiName());

        Test.stopTest();
        
    }
}