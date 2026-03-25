/**
 * @author      WDCi (Lean)
 * @date        Jul 2024
 * @group       Test
 * @description Test class for REDU_CustomRollupManager
 * @changehistory
 * ISS-001993 02-07-2024 Lean - new class
 */
@IsTest
public inherited sharing class REDU_CustomRollupManager_TEST {

    static final REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
    /**
     * @description Default method to setup required data for automated test
     */
	@TestSetup
    static void makeData(){
        testFactory.setupDefaultSettings();
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupCountInsert(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            
        
        //Create trigger controller
        reduivy__Trigger_Controller__mdt triggerControllerContact = SOBJ_CustomRollup_TEST.createTriggerControllerContact();

        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(triggerControllerContact);
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerContact.reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigCOUNT = SOBJ_CustomRollup_TEST.createCustomRollupConfigCOUNT();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigCOUNT);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigCOUNT.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerContact.reduivy__SObject__c, customRollupConfigsByParent);

        //Insert account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        //Create contacts
        List<Contact> contactList = new List<Contact>();        
        Contact testContact1 = new Contact(AccountId = testAccount.Id, LastName = 'Test1');
        Contact testContact2 = new Contact(AccountId = testAccount.Id, LastName = 'Test2');
        contactList.add(testContact1);
        contactList.add(testContact2);

        //Insert contacts
        Test.startTest();
        insert contactList;
        Test.stopTest();

        //Assert rollup was successful
        testAccount = [SELECT NumberOfEmployees FROM Account WHERE Name = 'Test Account' LIMIT 1];

        System.Assert.areEqual(contactList.size(), testAccount.NumberOfEmployees);
        }
    }
    
}