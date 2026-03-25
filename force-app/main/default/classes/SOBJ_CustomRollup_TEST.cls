/**
 * @author      WDCi (Jordan)
 * @date        Feb 2024
 * @group       Test
 * @description Test class for SOBJ_CustomRollup_EXE
 * @changehistory
 * ISS-001847 07-02-2024 Jordan - new test class
 * ISS-001967 21-06-2024 Sueanne - include decimal test for sum currency
 */
@IsTest
public inherited sharing class SOBJ_CustomRollup_TEST {
 
    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();	

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
        
        //Create trigger controller
        reduivy__Trigger_Controller__mdt triggerControllerContact = createTriggerControllerContact();

        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(triggerControllerContact);
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerContact.reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigCOUNT = createCustomRollupConfigCOUNT();
        
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

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupCountUpdate(){
        
        //Create trigger controller
        reduivy__Trigger_Controller__mdt triggerControllerContact = createTriggerControllerContact();

        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(triggerControllerContact);
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerContact.reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigCOUNT = createCustomRollupConfigCOUNT();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigCOUNT);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigCOUNT.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerContact.reduivy__SObject__c, customRollupConfigsByParent);

        //Insert account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        //Insert contacts
        List<Contact> contactList = new List<Contact>();        
        Contact testContact1 = new Contact(AccountId = testAccount.Id, LastName = 'Test1');
        Contact testContact2 = new Contact(AccountId = testAccount.Id, LastName = 'Test2');
        contactList.add(testContact1);
        contactList.add(testContact2);
        insert contactList;

        //Edit contact
        testContact1.LastName = 'Test1 Updated';

        //Update contact
        Test.startTest();
        update contactList;
        Test.stopTest();

        //Assert rollup was successful
        testAccount = [SELECT NumberOfEmployees FROM Account WHERE Name = 'Test Account' LIMIT 1];

        System.Assert.areEqual(contactList.size(), testAccount.NumberOfEmployees);
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupCountDelete(){
        
        //Create trigger controller
        reduivy__Trigger_Controller__mdt triggerControllerContact = createTriggerControllerContact();

        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(triggerControllerContact);
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerContact.reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigCOUNT = createCustomRollupConfigCOUNT();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigCOUNT);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigCOUNT.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerContact.reduivy__SObject__c, customRollupConfigsByParent);

        //Insert account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        //Insert contacts
        List<Contact> contactList = new List<Contact>();        
        Contact testContact1 = new Contact(AccountId = testAccount.Id, LastName = 'Test1');
        Contact testContact2 = new Contact(AccountId = testAccount.Id, LastName = 'Test2');
        contactList.add(testContact1);
        contactList.add(testContact2);
        insert contactList;

        //Delete contacts
        Test.startTest();
        delete contactList;
        Test.stopTest();

        //Assert rollup was successful
        testAccount = [SELECT NumberOfEmployees FROM Account WHERE Name = 'Test Account' LIMIT 1];

        System.Assert.areEqual(0, testAccount.NumberOfEmployees);
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupCountUndelete(){
        
        //Create trigger controller
        reduivy__Trigger_Controller__mdt triggerControllerContact = createTriggerControllerContact();

        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(triggerControllerContact);
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerContact.reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigCOUNT = createCustomRollupConfigCOUNT();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigCOUNT);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigCOUNT.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerContact.reduivy__SObject__c, customRollupConfigsByParent);

        //Insert account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        //Insert contacts
        List<Contact> contactList = new List<Contact>();        
        Contact testContact1 = new Contact(AccountId = testAccount.Id, LastName = 'Test1');
        Contact testContact2 = new Contact(AccountId = testAccount.Id, LastName = 'Test2');
        contactList.add(testContact1);
        contactList.add(testContact2);
        insert contactList;

        //Delete contacts
        delete contactList;

        //Undelete contacts
        Test.startTest();
        undelete contactList;
        Test.stopTest();

        //Assert rollup was successful
        testAccount = [SELECT NumberOfEmployees FROM Account WHERE Name = 'Test Account' LIMIT 1];

        System.Assert.areEqual(contactList.size(), testAccount.NumberOfEmployees);
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupMinNumericInsert(){
        
        //Create trigger controller
        reduivy__Trigger_Controller__mdt triggerControllerAccount = createTriggerControllerAccount();

        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(triggerControllerAccount);
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerAccount.reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigMINNUMERIC = createCustomRollupConfigMINNUMERIC();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigMINNUMERIC);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigMINNUMERIC.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerAccount.reduivy__SObject__c, customRollupConfigsByParent);

        //Insert parent account
        Account testParentAccount = new Account(Name = 'Test Parent Account');
        insert testParentAccount;

        //Create child accounts
        List<Account> childAccountList = new List<Account>();        
        Account testChildAccount1 = new Account(ParentId = testParentAccount.Id, Name = 'Test Child Account 1', NumberOfEmployees = 5);
        Account testChildAccount2 = new Account(ParentId = testParentAccount.Id, Name = 'Test Child Account 2', NumberOfEmployees = 10);
        childAccountList.add(testChildAccount1);
        childAccountList.add(testChildAccount2);

        //Insert child accounts
        Test.startTest();
        insert childAccountList;
        Test.stopTest();

        //Assert rollup was successful
        testParentAccount = [SELECT NumberOfEmployees FROM Account WHERE Name = 'Test Parent Account' LIMIT 1];

        System.Assert.areEqual(5, testParentAccount.NumberOfEmployees);
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupMinNumericUpdate(){
        
        //Create trigger controller
        reduivy__Trigger_Controller__mdt triggerControllerAccount = createTriggerControllerAccount();

        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(triggerControllerAccount);
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerAccount.reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigMINNUMERIC = createCustomRollupConfigMINNUMERIC();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigMINNUMERIC);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigMINNUMERIC.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerAccount.reduivy__SObject__c, customRollupConfigsByParent);

        //Insert parent account
        Account testParentAccount = new Account(Name = 'Test Parent Account');
        insert testParentAccount;

        //Insert child accounts
        List<Account> childAccountList = new List<Account>();        
        Account testChildAccount1 = new Account(ParentId = testParentAccount.Id, Name = 'Test Child Account 1', NumberOfEmployees = 5);
        Account testChildAccount2 = new Account(ParentId = testParentAccount.Id, Name = 'Test Child Account 2', NumberOfEmployees = 10);
        childAccountList.add(testChildAccount1);
        childAccountList.add(testChildAccount2);
        insert childAccountList;

        //Edit child account
        testChildAccount1.NumberOfEmployees = 15;

        //Update child account
        Test.startTest();
        update testChildAccount1;
        Test.stopTest();

        //Assert rollup was successful
        testParentAccount = [SELECT NumberOfEmployees FROM Account WHERE Name = 'Test Parent Account' LIMIT 1];

        System.Assert.areEqual(10, testParentAccount.NumberOfEmployees);
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupMinNumericDelete(){
        
        //Create trigger controller
        reduivy__Trigger_Controller__mdt triggerControllerAccount = createTriggerControllerAccount();

        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(triggerControllerAccount);
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerAccount.reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigMINNUMERIC = createCustomRollupConfigMINNUMERIC();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigMINNUMERIC);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigMINNUMERIC.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerAccount.reduivy__SObject__c, customRollupConfigsByParent);

        //Insert parent account
        Account testParentAccount = new Account(Name = 'Test Parent Account');
        insert testParentAccount;

        //Insert child accounts
        List<Account> childAccountList = new List<Account>();        
        Account testChildAccount1 = new Account(ParentId = testParentAccount.Id, Name = 'Test Child Account 1', NumberOfEmployees = 5);
        Account testChildAccount2 = new Account(ParentId = testParentAccount.Id, Name = 'Test Child Account 2', NumberOfEmployees = 10);
        childAccountList.add(testChildAccount1);
        childAccountList.add(testChildAccount2);
        insert childAccountList;

        //Delete child account
        Test.startTest();
        delete childAccountList;
        Test.stopTest();

        //Assert rollup was successful
        testParentAccount = [SELECT NumberOfEmployees FROM Account WHERE Name = 'Test Parent Account' LIMIT 1];

        System.Assert.areEqual(0, testParentAccount.NumberOfEmployees);
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupMinNumericUndelete(){
        
        //Create trigger controller
        reduivy__Trigger_Controller__mdt triggerControllerAccount = createTriggerControllerAccount();

        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(triggerControllerAccount);
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerAccount.reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigMINNUMERIC = createCustomRollupConfigMINNUMERIC();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigMINNUMERIC);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigMINNUMERIC.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerAccount.reduivy__SObject__c, customRollupConfigsByParent);

        //Insert parent account
        Account testParentAccount = new Account(Name = 'Test Parent Account');
        insert testParentAccount;

        //Insert child accounts
        List<Account> childAccountList = new List<Account>();        
        Account testChildAccount1 = new Account(ParentId = testParentAccount.Id, Name = 'Test Child Account 1', NumberOfEmployees = 5);
        Account testChildAccount2 = new Account(ParentId = testParentAccount.Id, Name = 'Test Child Account 2', NumberOfEmployees = 10);
        childAccountList.add(testChildAccount1);
        childAccountList.add(testChildAccount2);
        insert childAccountList;

        //Delete child account
        delete testChildAccount1;

        //Undelete child account
        Test.startTest();
        undelete testChildAccount1;
        Test.stopTest();

        //Assert rollup was successful
        testParentAccount = [SELECT NumberOfEmployees FROM Account WHERE Name = 'Test Parent Account' LIMIT 1];

        System.Assert.areEqual(5, testParentAccount.NumberOfEmployees);
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupMaxNumericInsert(){
        
        //Create trigger controller
        reduivy__Trigger_Controller__mdt triggerControllerAccount = createTriggerControllerAccount();

        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(triggerControllerAccount);
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerAccount.reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigMAXNUMERIC = createCustomRollupConfigMAXNUMERIC();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigMAXNUMERIC);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigMAXNUMERIC.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerAccount.reduivy__SObject__c, customRollupConfigsByParent);

        //Insert parent account
        Account testParentAccount = new Account(Name = 'Test Parent Account');
        insert testParentAccount;

        //Create child accounts
        List<Account> childAccountList = new List<Account>();        
        Account testChildAccount1 = new Account(ParentId = testParentAccount.Id, Name = 'Test Child Account 1', NumberOfEmployees = 5);
        Account testChildAccount2 = new Account(ParentId = testParentAccount.Id, Name = 'Test Child Account 2', NumberOfEmployees = 10);
        childAccountList.add(testChildAccount1);
        childAccountList.add(testChildAccount2);

        //Insert child accounts
        Test.startTest();
        insert childAccountList;
        Test.stopTest();

        //Assert rollup was successful
        testParentAccount = [SELECT NumberOfEmployees FROM Account WHERE Name = 'Test Parent Account' LIMIT 1];

        System.Assert.areEqual(10, testParentAccount.NumberOfEmployees);
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupMaxNumericUpdate(){
        
        //Create trigger controller
        reduivy__Trigger_Controller__mdt triggerControllerAccount = createTriggerControllerAccount();

        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(triggerControllerAccount);
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerAccount.reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigMAXNUMERIC = createCustomRollupConfigMAXNUMERIC();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigMAXNUMERIC);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigMAXNUMERIC.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerAccount.reduivy__SObject__c, customRollupConfigsByParent);

        //Insert parent account
        Account testParentAccount = new Account(Name = 'Test Parent Account');
        insert testParentAccount;

        //Insert child accounts
        List<Account> childAccountList = new List<Account>();        
        Account testChildAccount1 = new Account(ParentId = testParentAccount.Id, Name = 'Test Child Account 1', NumberOfEmployees = 5);
        Account testChildAccount2 = new Account(ParentId = testParentAccount.Id, Name = 'Test Child Account 2', NumberOfEmployees = 10);
        childAccountList.add(testChildAccount1);
        childAccountList.add(testChildAccount2);
        insert childAccountList;

        //Edit child account
        testChildAccount1.NumberOfEmployees = 15;

        //Update child account
        Test.startTest();
        update testChildAccount1;
        Test.stopTest();

        //Assert rollup was successful
        testParentAccount = [SELECT NumberOfEmployees FROM Account WHERE Name = 'Test Parent Account' LIMIT 1];

        System.Assert.areEqual(15, testParentAccount.NumberOfEmployees);
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupMaxNumericDelete(){
        
        //Create trigger controller
        reduivy__Trigger_Controller__mdt triggerControllerAccount = createTriggerControllerAccount();

        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(triggerControllerAccount);
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerAccount.reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigMAXNUMERIC = createCustomRollupConfigMAXNUMERIC();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigMAXNUMERIC);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigMAXNUMERIC.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerAccount.reduivy__SObject__c, customRollupConfigsByParent);

        //Insert parent account
        Account testParentAccount = new Account(Name = 'Test Parent Account');
        insert testParentAccount;

        //Insert child accounts
        List<Account> childAccountList = new List<Account>();        
        Account testChildAccount1 = new Account(ParentId = testParentAccount.Id, Name = 'Test Child Account 1', NumberOfEmployees = 5);
        Account testChildAccount2 = new Account(ParentId = testParentAccount.Id, Name = 'Test Child Account 2', NumberOfEmployees = 10);
        childAccountList.add(testChildAccount1);
        childAccountList.add(testChildAccount2);
        insert childAccountList;

        //Delete child account
        Test.startTest();
        delete childAccountList;
        Test.stopTest();

        //Assert rollup was successful
        testParentAccount = [SELECT NumberOfEmployees FROM Account WHERE Name = 'Test Parent Account' LIMIT 1];

        System.Assert.areEqual(0, testParentAccount.NumberOfEmployees);
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupMaxNumericUndelete(){
        
        //Create trigger controller
        reduivy__Trigger_Controller__mdt triggerControllerAccount = createTriggerControllerAccount();

        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(triggerControllerAccount);
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerAccount.reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigMAXNUMERIC = createCustomRollupConfigMAXNUMERIC();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigMAXNUMERIC);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigMAXNUMERIC.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerAccount.reduivy__SObject__c, customRollupConfigsByParent);

        //Insert parent account
        Account testParentAccount = new Account(Name = 'Test Parent Account');
        insert testParentAccount;

        //Insert child accounts
        List<Account> childAccountList = new List<Account>();        
        Account testChildAccount1 = new Account(ParentId = testParentAccount.Id, Name = 'Test Child Account 1', NumberOfEmployees = 5);
        Account testChildAccount2 = new Account(ParentId = testParentAccount.Id, Name = 'Test Child Account 2', NumberOfEmployees = 10);
        childAccountList.add(testChildAccount1);
        childAccountList.add(testChildAccount2);
        insert childAccountList;

        //Delete child account
        delete testChildAccount2;

        //Undelete child account
        Test.startTest();
        undelete testChildAccount2;
        Test.stopTest();

        //Assert rollup was successful
        testParentAccount = [SELECT NumberOfEmployees FROM Account WHERE Name = 'Test Parent Account' LIMIT 1];

        System.Assert.areEqual(10, testParentAccount.NumberOfEmployees);
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupMinDateInsert(){
        
        //Create trigger controller
        reduivy__Trigger_Controller__mdt triggerControllerContact = createTriggerControllerContact();

        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(triggerControllerContact);
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerContact.reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigMINDATE = createCustomRollupConfigMINDATE();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigMINDATE);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigMINDATE.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerContact.reduivy__SObject__c, customRollupConfigsByParent);

        //Insert parent contact
        Contact testParentContact = new Contact(LastName= 'TestParent');
        insert testParentContact;

        //Create child contacts
        List<Contact> childContactList = new List<Contact>();        
        Contact testChildContact1 = new Contact(ReportsToId = testParentContact.Id, LastName = 'Test1', Birthdate = Date.today());
        Contact testChildContact2 = new Contact(ReportsToId = testParentContact.Id, LastName = 'Test2', Birthdate = Date.today() + 7);
        childContactList.add(testChildContact1);
        childContactList.add(testChildContact2);

        //Insert child accounts
        Test.startTest();
        insert childContactList;
        Test.stopTest();

        //Assert rollup was successful
        testParentContact = [SELECT Birthdate FROM Contact WHERE LastName = 'TestParent' LIMIT 1];

        System.Assert.areEqual(Date.today(), testParentContact.Birthdate);
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupMinDateUpdate(){
        
        //Create trigger controller
        reduivy__Trigger_Controller__mdt triggerControllerContact = createTriggerControllerContact();

        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(triggerControllerContact);
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerContact.reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigMINDATE = createCustomRollupConfigMINDATE();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigMINDATE);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigMINDATE.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerContact.reduivy__SObject__c, customRollupConfigsByParent);

        //Insert parent contact
        Contact testParentContact = new Contact(LastName= 'TestParent');
        insert testParentContact;

        //Insert child accounts
        List<Contact> childContactList = new List<Contact>();        
        Contact testChildContact1 = new Contact(ReportsToId = testParentContact.Id, LastName = 'Test1', Birthdate = Date.today());
        Contact testChildContact2 = new Contact(ReportsToId = testParentContact.Id, LastName = 'Test2', Birthdate = Date.today() + 7);
        childContactList.add(testChildContact1);
        childContactList.add(testChildContact2);
        insert childContactList;

        //Edit child account
        testChildContact1.Birthdate = Date.today() + 14;

        //Update child account
        Test.startTest();
        update testChildContact1;
        Test.stopTest();

        //Assert rollup was successful
        testParentContact = [SELECT Birthdate FROM Contact WHERE LastName = 'TestParent' LIMIT 1];

        System.Assert.areEqual(Date.today() + 7, testParentContact.Birthdate);
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupMinDateDelete(){
        
        //Create trigger controller
        reduivy__Trigger_Controller__mdt triggerControllerContact = createTriggerControllerContact();

        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(triggerControllerContact);
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerContact.reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigMINDATE = createCustomRollupConfigMINDATE();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigMINDATE);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigMINDATE.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerContact.reduivy__SObject__c, customRollupConfigsByParent);

        //Insert parent contact
        Contact testParentContact = new Contact(LastName= 'TestParent');
        insert testParentContact;

        //Insert child accounts
        List<Contact> childContactList = new List<Contact>();        
        Contact testChildContact1 = new Contact(ReportsToId = testParentContact.Id, LastName = 'Test1', Birthdate = Date.today());
        Contact testChildContact2 = new Contact(ReportsToId = testParentContact.Id, LastName = 'Test2', Birthdate = Date.today() + 7);
        childContactList.add(testChildContact1);
        childContactList.add(testChildContact2);
        insert childContactList;

        //Delete child account
        Test.startTest();
        delete childContactList;
        Test.stopTest();

        //Assert rollup was successful
        testParentContact = [SELECT Birthdate FROM Contact WHERE LastName = 'TestParent' LIMIT 1];

        System.Assert.areEqual(null, testParentContact.Birthdate);
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupMinDateUndelete(){
        
        //Create trigger controller
        reduivy__Trigger_Controller__mdt triggerControllerContact = createTriggerControllerContact();

        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(triggerControllerContact);
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerContact.reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigMINDATE = createCustomRollupConfigMINDATE();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigMINDATE);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigMINDATE.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerContact.reduivy__SObject__c, customRollupConfigsByParent);

        //Insert parent contact
        Contact testParentContact = new Contact(LastName= 'TestParent');
        insert testParentContact;

        //Insert child accounts
        List<Contact> childContactList = new List<Contact>();        
        Contact testChildContact1 = new Contact(ReportsToId = testParentContact.Id, LastName = 'Test1', Birthdate = Date.today());
        Contact testChildContact2 = new Contact(ReportsToId = testParentContact.Id, LastName = 'Test2', Birthdate = Date.today() + 7);
        childContactList.add(testChildContact1);
        childContactList.add(testChildContact2);
        insert childContactList;

        //Delete child account
        delete testChildContact1;

        //Undelete child account
        Test.startTest();
        undelete testChildContact1;
        Test.stopTest();

        //Assert rollup was successful
        testParentContact = [SELECT Birthdate FROM Contact WHERE LastName = 'TestParent' LIMIT 1];

        System.Assert.areEqual(Date.today(), testParentContact.Birthdate);
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupMaxDateInsert(){
        
        //Create trigger controller
        reduivy__Trigger_Controller__mdt triggerControllerContact = createTriggerControllerContact();

        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(triggerControllerContact);
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerContact.reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigMAXDATE = createCustomRollupConfigMAXDATE();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigMAXDATE);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigMAXDATE.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerContact.reduivy__SObject__c, customRollupConfigsByParent);

        //Insert parent contact
        Contact testParentContact = new Contact(LastName= 'TestParent');
        insert testParentContact;

        //Create child contacts
        List<Contact> childContactList = new List<Contact>();        
        Contact testChildContact1 = new Contact(ReportsToId = testParentContact.Id, LastName = 'Test1', Birthdate = Date.today());
        Contact testChildContact2 = new Contact(ReportsToId = testParentContact.Id, LastName = 'Test2', Birthdate = Date.today() + 7);
        childContactList.add(testChildContact1);
        childContactList.add(testChildContact2);

        //Insert child accounts
        Test.startTest();
        insert childContactList;
        Test.stopTest();

        //Assert rollup was successful
        testParentContact = [SELECT Birthdate FROM Contact WHERE LastName = 'TestParent' LIMIT 1];

        System.Assert.areEqual(Date.today() + 7, testParentContact.Birthdate);
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupMaxDateUpdate(){
        
        //Create trigger controller
        reduivy__Trigger_Controller__mdt triggerControllerContact = createTriggerControllerContact();

        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(triggerControllerContact);
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerContact.reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigMAXDATE = createCustomRollupConfigMAXDATE();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigMAXDATE);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigMAXDATE.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerContact.reduivy__SObject__c, customRollupConfigsByParent);

        //Insert parent contact
        Contact testParentContact = new Contact(LastName= 'TestParent');
        insert testParentContact;

        //Insert child accounts
        List<Contact> childContactList = new List<Contact>();        
        Contact testChildContact1 = new Contact(ReportsToId = testParentContact.Id, LastName = 'Test1', Birthdate = Date.today());
        Contact testChildContact2 = new Contact(ReportsToId = testParentContact.Id, LastName = 'Test2', Birthdate = Date.today() + 7);
        childContactList.add(testChildContact1);
        childContactList.add(testChildContact2);
        insert childContactList;

        //Edit child account
        testChildContact1.Birthdate = Date.today() + 14;

        //Update child account
        Test.startTest();
        update testChildContact1;
        Test.stopTest();

        //Assert rollup was successful
        testParentContact = [SELECT Birthdate FROM Contact WHERE LastName = 'TestParent' LIMIT 1];

        System.Assert.areEqual(Date.today() + 14, testParentContact.Birthdate);
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupMaxDateDelete(){
        
        //Create trigger controller
        reduivy__Trigger_Controller__mdt triggerControllerContact = createTriggerControllerContact();

        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(triggerControllerContact);
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerContact.reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigMAXDATE = createCustomRollupConfigMAXDATE();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigMAXDATE);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigMAXDATE.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerContact.reduivy__SObject__c, customRollupConfigsByParent);

        //Insert parent contact
        Contact testParentContact = new Contact(LastName= 'TestParent');
        insert testParentContact;

        //Insert child accounts
        List<Contact> childContactList = new List<Contact>();        
        Contact testChildContact1 = new Contact(ReportsToId = testParentContact.Id, LastName = 'Test1', Birthdate = Date.today());
        Contact testChildContact2 = new Contact(ReportsToId = testParentContact.Id, LastName = 'Test2', Birthdate = Date.today() + 7);
        childContactList.add(testChildContact1);
        childContactList.add(testChildContact2);
        insert childContactList;

        //Delete child account
        Test.startTest();
        delete childContactList;
        Test.stopTest();

        //Assert rollup was successful
        testParentContact = [SELECT Birthdate FROM Contact WHERE LastName = 'TestParent' LIMIT 1];

        System.Assert.areEqual(null, testParentContact.Birthdate);
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupMaxDateUndelete(){
        
        //Create trigger controller
        reduivy__Trigger_Controller__mdt triggerControllerContact = createTriggerControllerContact();

        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(triggerControllerContact);
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerContact.reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigMAXDATE = createCustomRollupConfigMAXDATE();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigMAXDATE);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigMAXDATE.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerContact.reduivy__SObject__c, customRollupConfigsByParent);

        //Insert parent contact
        Contact testParentContact = new Contact(LastName= 'TestParent');
        insert testParentContact;

        //Insert child accounts
        List<Contact> childContactList = new List<Contact>();        
        Contact testChildContact1 = new Contact(ReportsToId = testParentContact.Id, LastName = 'Test1', Birthdate = Date.today());
        Contact testChildContact2 = new Contact(ReportsToId = testParentContact.Id, LastName = 'Test2', Birthdate = Date.today() + 7);
        childContactList.add(testChildContact1);
        childContactList.add(testChildContact2);
        insert childContactList;

        //Delete child account
        delete testChildContact2;

        //Undelete child account
        Test.startTest();
        undelete testChildContact2;
        Test.stopTest();

        //Assert rollup was successful
        testParentContact = [SELECT Birthdate FROM Contact WHERE LastName = 'TestParent' LIMIT 1];

        System.Assert.areEqual(Date.today() + 7, testParentContact.Birthdate);
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupMinCurrencyInsert(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        //Create trigger controller
        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(createTriggerControllerTransactionLineItem1());
        triggerControllerConfigs.add(createTriggerControllerTransactionLineItem2());
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerConfigs[0].reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigMINCURRENCY = createCustomRollupConfigMINCURRENCY();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigMINCURRENCY);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigMINCURRENCY.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerConfigs[0].reduivy__SObject__c, customRollupConfigsByParent);

        //Insert contact
        Contact testContact = new Contact(LastName= 'Test');
        insert testContact;

        //Insert transaction order
        reduivy__Transaction_Order__c testTransactionOrder = REDU_TestData_UTIL.newTransactionOrder('Test_Order', testContact.Id, null, date.today(), TRO_Helper.getDraftStatuses().get(0), 0, 0, 0);
        //new reduivy__Transaction_Order__c(reduivy__Contact__c = testContact.Id);
        insert testTransactionOrder;

        //Create transaction line items
        List<reduivy__Transaction_Line_Item__c> transactionLineItemList = new List<reduivy__Transaction_Line_Item__c>();
        transactionLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(testTransactionOrder.reduivy__Sample_Record_Code__c + '|Application', testTransactionOrder.Id, null, 'Admission Fee', 'Application', 100, null, null));
        transactionLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(testTransactionOrder.reduivy__Sample_Record_Code__c + '|Deposit', testTransactionOrder.Id, null, 'Deposit', 'Deposit', 500, null, null));

        System.runAs(ADMIN_USER){
            //Insert transaction line items
            Test.startTest();
            insert transactionLineItemList;
            Test.stopTest();
        }
        
        //Assert rollup was successful
        testTransactionOrder = [SELECT reduivy__Total_Amount__c FROM reduivy__Transaction_Order__c WHERE reduivy__Contact__c = :testContact.Id LIMIT 1];

        System.Assert.areEqual(100, testTransactionOrder.reduivy__Total_Amount__c);
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupMinCurrencyUpdate(){
        
        //Create trigger controller
        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(createTriggerControllerTransactionLineItem1());
        triggerControllerConfigs.add(createTriggerControllerTransactionLineItem2());
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerConfigs[0].reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigMINCURRENCY = createCustomRollupConfigMINCURRENCY();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigMINCURRENCY);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigMINCURRENCY.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerConfigs[0].reduivy__SObject__c, customRollupConfigsByParent);

        //Insert contact
        Contact testContact = new Contact(LastName= 'Test');
        insert testContact;

        //Insert transaction order
        reduivy__Transaction_Order__c testTransactionOrder = new reduivy__Transaction_Order__c(reduivy__Contact__c = testContact.Id);
        insert testTransactionOrder;

        //Insert transaction line items
        List<reduivy__Transaction_Line_Item__c> transactionLineItemList = new List<reduivy__Transaction_Line_Item__c>();        
        transactionLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(testTransactionOrder.reduivy__Sample_Record_Code__c + '|Application', testTransactionOrder.Id, null, 'Admission Fee', 'Application', 100, null, null));
        transactionLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(testTransactionOrder.reduivy__Sample_Record_Code__c + '|Deposit', testTransactionOrder.Id, null, 'Deposit', 'Deposit', 500, null, null));
        insert transactionLineItemList;

        //Edit transaction line item
        transactionLineItemList[0].reduivy__Total_Amount__c = 750;

        //Update transaction line item
        Test.startTest();
        update transactionLineItemList[0];
        Test.stopTest();

        //Assert rollup was successful
        testTransactionOrder = [SELECT reduivy__Total_Amount__c FROM reduivy__Transaction_Order__c WHERE reduivy__Contact__c = :testContact.Id LIMIT 1];

        System.Assert.areEqual(500, testTransactionOrder.reduivy__Total_Amount__c);
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupMinCurrencyDelete(){
        
        //Create trigger controller
        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(createTriggerControllerTransactionLineItem1());
        triggerControllerConfigs.add(createTriggerControllerTransactionLineItem2());
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerConfigs[0].reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigMINCURRENCY = createCustomRollupConfigMINCURRENCY();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigMINCURRENCY);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigMINCURRENCY.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerConfigs[0].reduivy__SObject__c, customRollupConfigsByParent);

        //Insert contact
        Contact testContact = new Contact(LastName= 'Test');
        insert testContact;

        //Insert transaction order
        reduivy__Transaction_Order__c testTransactionOrder = new reduivy__Transaction_Order__c(reduivy__Contact__c = testContact.Id);
        insert testTransactionOrder;

        //Insert transaction line items
        List<reduivy__Transaction_Line_Item__c> transactionLineItemList = new List<reduivy__Transaction_Line_Item__c>();        
        transactionLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(testTransactionOrder.reduivy__Sample_Record_Code__c + '|Application', testTransactionOrder.Id, null, 'Admission Fee', 'Application', 100, null, null));
		transactionLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(testTransactionOrder.reduivy__Sample_Record_Code__c + '|Deposit', testTransactionOrder.Id, null, 'Deposit', 'Deposit', 500, null, null));
        insert transactionLineItemList;

        //Delete transaction line item
        Test.startTest();
        delete transactionLineItemList;
        Test.stopTest();

        //Assert rollup was successful
        testTransactionOrder = [SELECT reduivy__Total_Amount__c FROM reduivy__Transaction_Order__c WHERE reduivy__Contact__c = :testContact.Id LIMIT 1];

        System.Assert.areEqual(0, testTransactionOrder.reduivy__Total_Amount__c);
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupMinCurrencyUndelete(){
        
        //Create trigger controller
        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(createTriggerControllerTransactionLineItem1());
        triggerControllerConfigs.add(createTriggerControllerTransactionLineItem2());
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerConfigs[0].reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigMINCURRENCY = createCustomRollupConfigMINCURRENCY();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigMINCURRENCY);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigMINCURRENCY.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerConfigs[0].reduivy__SObject__c, customRollupConfigsByParent);

        //Insert contact
        Contact testContact = new Contact(LastName= 'Test');
        insert testContact;

        //Insert transaction order
        reduivy__Transaction_Order__c testTransactionOrder = new reduivy__Transaction_Order__c(reduivy__Contact__c = testContact.Id);
        insert testTransactionOrder;

        //Insert transaction line items
        List<reduivy__Transaction_Line_Item__c> transactionLineItemList = new List<reduivy__Transaction_Line_Item__c>();        
        transactionLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(testTransactionOrder.reduivy__Sample_Record_Code__c + '|Application', testTransactionOrder.Id, null, 'Admission Fee', 'Application', 100, null, null));
		transactionLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(testTransactionOrder.reduivy__Sample_Record_Code__c + '|Deposit', testTransactionOrder.Id, null, 'Deposit', 'Deposit', 500, null, null));
        insert transactionLineItemList;

        //Delete transaction line item
        delete transactionLineItemList[0];

        //Undelete transaction line item
        Test.startTest();
        undelete transactionLineItemList[0];
        Test.stopTest();

        //Assert rollup was successful
        testTransactionOrder = [SELECT reduivy__Total_Amount__c FROM reduivy__Transaction_Order__c WHERE reduivy__Contact__c = :testContact.Id LIMIT 1];

        System.Assert.areEqual(100, testTransactionOrder.reduivy__Total_Amount__c);
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupMaxCurrencyInsert(){
        
        //Create trigger controller
        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(createTriggerControllerTransactionLineItem1());
        triggerControllerConfigs.add(createTriggerControllerTransactionLineItem2());
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerConfigs[0].reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigMAXCURRENCY = createCustomRollupConfigMAXCURRENCY();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigMAXCURRENCY);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigMAXCURRENCY.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerConfigs[0].reduivy__SObject__c, customRollupConfigsByParent);

        //Insert contact
        Contact testContact = new Contact(LastName= 'Test');
        insert testContact;

        //Insert transaction order
        reduivy__Transaction_Order__c testTransactionOrder = new reduivy__Transaction_Order__c(reduivy__Contact__c = testContact.Id);
        insert testTransactionOrder;

        //Create transaction line items
        List<reduivy__Transaction_Line_Item__c> transactionLineItemList = new List<reduivy__Transaction_Line_Item__c>();
        transactionLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(testTransactionOrder.reduivy__Sample_Record_Code__c + '|Application', testTransactionOrder.Id, null, 'Admission Fee', 'Application', 100, null, null));
		transactionLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(testTransactionOrder.reduivy__Sample_Record_Code__c + '|Deposit', testTransactionOrder.Id, null, 'Deposit', 'Deposit', 500, null, null));

        //Insert transaction line items
        Test.startTest();
        insert transactionLineItemList;
        Test.stopTest();
        
        //Assert rollup was successful
        testTransactionOrder = [SELECT reduivy__Total_Amount__c FROM reduivy__Transaction_Order__c WHERE reduivy__Contact__c = :testContact.Id LIMIT 1];

        System.Assert.areEqual(500, testTransactionOrder.reduivy__Total_Amount__c);
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupMaxCurrencyUpdate(){
        
        //Create trigger controller
        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(createTriggerControllerTransactionLineItem1());
        triggerControllerConfigs.add(createTriggerControllerTransactionLineItem2());
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerConfigs[0].reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigMAXCURRENCY = createCustomRollupConfigMAXCURRENCY();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigMAXCURRENCY);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigMAXCURRENCY.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerConfigs[0].reduivy__SObject__c, customRollupConfigsByParent);

        //Insert contact
        Contact testContact = new Contact(LastName= 'Test');
        insert testContact;

        //Insert transaction order
        reduivy__Transaction_Order__c testTransactionOrder = new reduivy__Transaction_Order__c(reduivy__Contact__c = testContact.Id);
        insert testTransactionOrder;

        //Insert transaction line items
        List<reduivy__Transaction_Line_Item__c> transactionLineItemList = new List<reduivy__Transaction_Line_Item__c>();        
        transactionLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(testTransactionOrder.reduivy__Sample_Record_Code__c + '|Application', testTransactionOrder.Id, null, 'Admission Fee', 'Application', 100, null, null));
		transactionLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(testTransactionOrder.reduivy__Sample_Record_Code__c + '|Deposit', testTransactionOrder.Id, null, 'Deposit', 'Deposit', 500, null, null));
        insert transactionLineItemList;

        //Edit transaction line item
        transactionLineItemList[1].reduivy__Total_Amount__c = 50;

        //Update transaction line item
        Test.startTest();
        update transactionLineItemList[1];
        Test.stopTest();

        //Assert rollup was successful
        testTransactionOrder = [SELECT reduivy__Total_Amount__c FROM reduivy__Transaction_Order__c WHERE reduivy__Contact__c = :testContact.Id LIMIT 1];

        System.Assert.areEqual(100, testTransactionOrder.reduivy__Total_Amount__c);
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupMaxCurrencyDelete(){
        
        //Create trigger controller
        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(createTriggerControllerTransactionLineItem1());
        triggerControllerConfigs.add(createTriggerControllerTransactionLineItem2());
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerConfigs[0].reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigMAXCURRENCY = createCustomRollupConfigMAXCURRENCY();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigMAXCURRENCY);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigMAXCURRENCY.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerConfigs[0].reduivy__SObject__c, customRollupConfigsByParent);

        //Insert contact
        Contact testContact = new Contact(LastName= 'Test');
        insert testContact;

        //Insert transaction order
        reduivy__Transaction_Order__c testTransactionOrder = new reduivy__Transaction_Order__c(reduivy__Contact__c = testContact.Id);
        insert testTransactionOrder;

        //Insert transaction line items
        List<reduivy__Transaction_Line_Item__c> transactionLineItemList = new List<reduivy__Transaction_Line_Item__c>();        
        transactionLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(testTransactionOrder.reduivy__Sample_Record_Code__c + '|Application', testTransactionOrder.Id, null, 'Admission Fee', 'Application', 100, null, null));
		transactionLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(testTransactionOrder.reduivy__Sample_Record_Code__c + '|Deposit', testTransactionOrder.Id, null, 'Deposit', 'Deposit', 500, null, null));
        insert transactionLineItemList;

        //Delete transaction line item
        Test.startTest();
        delete transactionLineItemList;
        Test.stopTest();

        //Assert rollup was successful
        testTransactionOrder = [SELECT reduivy__Total_Amount__c FROM reduivy__Transaction_Order__c WHERE reduivy__Contact__c = :testContact.Id LIMIT 1];

        System.Assert.areEqual(0, testTransactionOrder.reduivy__Total_Amount__c);
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupMaxCurrencyUndelete(){
        
        //Create trigger controller
        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(createTriggerControllerTransactionLineItem1());
        triggerControllerConfigs.add(createTriggerControllerTransactionLineItem2());
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerConfigs[0].reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigMAXCURRENCY = createCustomRollupConfigMAXCURRENCY();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigMAXCURRENCY);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigMAXCURRENCY.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerConfigs[0].reduivy__SObject__c, customRollupConfigsByParent);

        //Insert contact
        Contact testContact = new Contact(LastName= 'Test');
        insert testContact;

        //Insert transaction order
        reduivy__Transaction_Order__c testTransactionOrder = new reduivy__Transaction_Order__c(reduivy__Contact__c = testContact.Id);
        insert testTransactionOrder;

        //Insert transaction line items
        List<reduivy__Transaction_Line_Item__c> transactionLineItemList = new List<reduivy__Transaction_Line_Item__c>();        
        transactionLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(testTransactionOrder.reduivy__Sample_Record_Code__c + '|Application', testTransactionOrder.Id, null, 'Admission Fee', 'Application', 100, null, null));
		transactionLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(testTransactionOrder.reduivy__Sample_Record_Code__c + '|Deposit', testTransactionOrder.Id, null, 'Deposit', 'Deposit', 500, null, null));
        insert transactionLineItemList;

        //Delete transaction line item
        delete transactionLineItemList[0];

        //Undelete transaction line item
        Test.startTest();
        undelete transactionLineItemList[0];
        Test.stopTest();

        //Assert rollup was successful
        testTransactionOrder = [SELECT reduivy__Total_Amount__c FROM reduivy__Transaction_Order__c WHERE reduivy__Contact__c = :testContact.Id LIMIT 1];

        System.Assert.areEqual(500, testTransactionOrder.reduivy__Total_Amount__c);
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupSumNumericInsert(){
        
        //Create trigger controller
        reduivy__Trigger_Controller__mdt triggerControllerAccount = createTriggerControllerAccount();

        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(triggerControllerAccount);
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerAccount.reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigSUMNUMERIC = createCustomRollupConfigSUMNUMERIC();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigSUMNUMERIC);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigSUMNUMERIC.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerAccount.reduivy__SObject__c, customRollupConfigsByParent);

        //Insert parent account
        Account testParentAccount = new Account(Name = 'Test Parent Account');
        insert testParentAccount;

        //Create child accounts
        List<Account> childAccountList = new List<Account>();        
        Account testChildAccount1 = new Account(ParentId = testParentAccount.Id, Name = 'Test Child Account 1', NumberOfEmployees = 5);
        Account testChildAccount2 = new Account(ParentId = testParentAccount.Id, Name = 'Test Child Account 2', NumberOfEmployees = 10);
        childAccountList.add(testChildAccount1);
        childAccountList.add(testChildAccount2);

        //Insert child accounts
        Test.startTest();
        insert childAccountList;
        Test.stopTest();

        //Assert rollup was successful
        testParentAccount = [SELECT NumberOfEmployees FROM Account WHERE Name = 'Test Parent Account' LIMIT 1];

        System.Assert.areEqual(15, testParentAccount.NumberOfEmployees);
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupSumNumericUpdate(){
        
        //Create trigger controller
        reduivy__Trigger_Controller__mdt triggerControllerAccount = createTriggerControllerAccount();

        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(triggerControllerAccount);
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerAccount.reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigSUMNUMERIC = createCustomRollupConfigSUMNUMERIC();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigSUMNUMERIC);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigSUMNUMERIC.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerAccount.reduivy__SObject__c, customRollupConfigsByParent);

        //Insert parent account
        Account testParentAccount = new Account(Name = 'Test Parent Account');
        insert testParentAccount;

        //Insert child accounts
        List<Account> childAccountList = new List<Account>();        
        Account testChildAccount1 = new Account(ParentId = testParentAccount.Id, Name = 'Test Child Account 1', NumberOfEmployees = 5);
        Account testChildAccount2 = new Account(ParentId = testParentAccount.Id, Name = 'Test Child Account 2', NumberOfEmployees = 10);
        childAccountList.add(testChildAccount1);
        childAccountList.add(testChildAccount2);
        insert childAccountList;

        //Edit child account
        testChildAccount1.NumberOfEmployees = 15;

        //Update child account
        Test.startTest();
        update testChildAccount1;
        Test.stopTest();

        //Assert rollup was successful
        testParentAccount = [SELECT NumberOfEmployees FROM Account WHERE Name = 'Test Parent Account' LIMIT 1];

        System.Assert.areEqual(25, testParentAccount.NumberOfEmployees);
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupSumNumericDelete(){
        
        //Create trigger controller
        reduivy__Trigger_Controller__mdt triggerControllerAccount = createTriggerControllerAccount();

        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(triggerControllerAccount);
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerAccount.reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigSUMNUMERIC = createCustomRollupConfigSUMNUMERIC();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigSUMNUMERIC);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigSUMNUMERIC.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerAccount.reduivy__SObject__c, customRollupConfigsByParent);

        //Insert parent account
        Account testParentAccount = new Account(Name = 'Test Parent Account');
        insert testParentAccount;

        //Insert child accounts
        List<Account> childAccountList = new List<Account>();        
        Account testChildAccount1 = new Account(ParentId = testParentAccount.Id, Name = 'Test Child Account 1', NumberOfEmployees = 5);
        Account testChildAccount2 = new Account(ParentId = testParentAccount.Id, Name = 'Test Child Account 2', NumberOfEmployees = 10);
        childAccountList.add(testChildAccount1);
        childAccountList.add(testChildAccount2);
        insert childAccountList;

        //Delete child account
        Test.startTest();
        delete childAccountList;
        Test.stopTest();

        //Assert rollup was successful
        testParentAccount = [SELECT NumberOfEmployees FROM Account WHERE Name = 'Test Parent Account' LIMIT 1];

        System.Assert.areEqual(0, testParentAccount.NumberOfEmployees);
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupSumNumericUndelete(){
        
        //Create trigger controller
        reduivy__Trigger_Controller__mdt triggerControllerAccount = createTriggerControllerAccount();

        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(triggerControllerAccount);
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerAccount.reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigSUMNUMERIC = createCustomRollupConfigSUMNUMERIC();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigSUMNUMERIC);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigSUMNUMERIC.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerAccount.reduivy__SObject__c, customRollupConfigsByParent);

        //Insert parent account
        Account testParentAccount = new Account(Name = 'Test Parent Account');
        insert testParentAccount;

        //Insert child accounts
        List<Account> childAccountList = new List<Account>();        
        Account testChildAccount1 = new Account(ParentId = testParentAccount.Id, Name = 'Test Child Account 1', NumberOfEmployees = 5);
        Account testChildAccount2 = new Account(ParentId = testParentAccount.Id, Name = 'Test Child Account 2', NumberOfEmployees = 10);
        childAccountList.add(testChildAccount1);
        childAccountList.add(testChildAccount2);
        insert childAccountList;

        //Delete child account
        delete testChildAccount1;

        //Undelete child account
        Test.startTest();
        undelete testChildAccount1;
        Test.stopTest();

        //Assert rollup was successful
        testParentAccount = [SELECT NumberOfEmployees FROM Account WHERE Name = 'Test Parent Account' LIMIT 1];

        System.Assert.areEqual(15, testParentAccount.NumberOfEmployees);
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupSumCurrencyInsert(){
        
        //Create trigger controller
        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(createTriggerControllerTransactionLineItem1());
        triggerControllerConfigs.add(createTriggerControllerTransactionLineItem2());
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerConfigs[0].reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigSUMCURRENCY = createCustomRollupConfigSUMCURRENCY();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigSUMCURRENCY);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigSUMCURRENCY.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerConfigs[0].reduivy__SObject__c, customRollupConfigsByParent);

        //Insert contact
        Contact testContact = new Contact(LastName= 'Test');
        insert testContact;

        //Insert transaction order
        reduivy__Transaction_Order__c testTransactionOrder = new reduivy__Transaction_Order__c(reduivy__Contact__c = testContact.Id);
        insert testTransactionOrder;

        //Create transaction line items
        List<reduivy__Transaction_Line_Item__c> transactionLineItemList = new List<reduivy__Transaction_Line_Item__c>();
        transactionLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(testTransactionOrder.reduivy__Sample_Record_Code__c + '|Application', testTransactionOrder.Id, null, 'Admission Fee', 'Application', 100.10, null, null));
	    transactionLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(testTransactionOrder.reduivy__Sample_Record_Code__c + '|Deposit', testTransactionOrder.Id, null, 'Deposit', 'Deposit', 500.20, null, null));

        //Insert transaction line items
        Test.startTest();
        insert transactionLineItemList;
        Test.stopTest();

        //Assert rollup was successful
        testTransactionOrder = [SELECT reduivy__Total_Amount__c FROM reduivy__Transaction_Order__c WHERE reduivy__Contact__c = :testContact.Id LIMIT 1];

        System.Assert.areEqual(600.30, testTransactionOrder.reduivy__Total_Amount__c);
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupSumCurrencyUpdate(){
        
        //Create trigger controller
        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(createTriggerControllerTransactionLineItem1());
        triggerControllerConfigs.add(createTriggerControllerTransactionLineItem2());
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerConfigs[0].reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigSUMCURRENCY = createCustomRollupConfigSUMCURRENCY();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigSUMCURRENCY);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigSUMCURRENCY.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerConfigs[0].reduivy__SObject__c, customRollupConfigsByParent);

        //Insert contact
        Contact testContact = new Contact(LastName= 'Test');
        insert testContact;

        //Insert transaction order
        reduivy__Transaction_Order__c testTransactionOrder = new reduivy__Transaction_Order__c(reduivy__Contact__c = testContact.Id);
        insert testTransactionOrder;

        //Insert transaction line items
        List<reduivy__Transaction_Line_Item__c> transactionLineItemList = new List<reduivy__Transaction_Line_Item__c>();        
        transactionLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(testTransactionOrder.reduivy__Sample_Record_Code__c + '|Application', testTransactionOrder.Id, null, 'Admission Fee', 'Application', 100.10, null, null));
		transactionLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(testTransactionOrder.reduivy__Sample_Record_Code__c + '|Deposit', testTransactionOrder.Id, null, 'Deposit', 'Deposit', 500.20, null, null));
        insert transactionLineItemList;

        //Edit transaction line item
        transactionLineItemList[1].reduivy__Total_Amount__c = 50.30;

        //Update transaction line item
        Test.startTest();
        update transactionLineItemList[1];
        Test.stopTest();

        //Assert rollup was successful
        testTransactionOrder = [SELECT reduivy__Total_Amount__c FROM reduivy__Transaction_Order__c WHERE reduivy__Contact__c = :testContact.Id LIMIT 1];

        System.Assert.areEqual(150.40, testTransactionOrder.reduivy__Total_Amount__c);
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupSumCurrencyDelete(){
        
        //Create trigger controller
        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(createTriggerControllerTransactionLineItem1());
        triggerControllerConfigs.add(createTriggerControllerTransactionLineItem2());
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerConfigs[0].reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigSUMCURRENCY = createCustomRollupConfigSUMCURRENCY();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigSUMCURRENCY);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigSUMCURRENCY.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerConfigs[0].reduivy__SObject__c, customRollupConfigsByParent);

        //Insert contact
        Contact testContact = new Contact(LastName= 'Test');
        insert testContact;

        //Insert transaction order
        reduivy__Transaction_Order__c testTransactionOrder = new reduivy__Transaction_Order__c(reduivy__Contact__c = testContact.Id);
        insert testTransactionOrder;

        //Insert transaction line items
        List<reduivy__Transaction_Line_Item__c> transactionLineItemList = new List<reduivy__Transaction_Line_Item__c>();        
        transactionLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(testTransactionOrder.reduivy__Sample_Record_Code__c + '|Application', testTransactionOrder.Id, null, 'Admission Fee', 'Application', 100.10, null, null));
		transactionLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(testTransactionOrder.reduivy__Sample_Record_Code__c + '|Deposit', testTransactionOrder.Id, null, 'Deposit', 'Deposit', 500.20, null, null));
        insert transactionLineItemList;

        //Delete transaction line item
        Test.startTest();
        delete transactionLineItemList;
        Test.stopTest();

        //Assert rollup was successful
        testTransactionOrder = [SELECT reduivy__Total_Amount__c FROM reduivy__Transaction_Order__c WHERE reduivy__Contact__c = :testContact.Id LIMIT 1];

        System.Assert.areEqual(0, testTransactionOrder.reduivy__Total_Amount__c);
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupSumCurrencyUndelete(){
        
        //Create trigger controller
        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(createTriggerControllerTransactionLineItem1());
        triggerControllerConfigs.add(createTriggerControllerTransactionLineItem2());
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerConfigs[0].reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigSUMCURRENCY = createCustomRollupConfigSUMCURRENCY();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigSUMCURRENCY);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigSUMCURRENCY.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerConfigs[0].reduivy__SObject__c, customRollupConfigsByParent);

        //Insert contact
        Contact testContact = new Contact(LastName= 'Test');
        insert testContact;

        //Insert transaction order
        reduivy__Transaction_Order__c testTransactionOrder = new reduivy__Transaction_Order__c(reduivy__Contact__c = testContact.Id);
        insert testTransactionOrder;

        //Insert transaction line items
        List<reduivy__Transaction_Line_Item__c> transactionLineItemList = new List<reduivy__Transaction_Line_Item__c>();        
        transactionLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(testTransactionOrder.reduivy__Sample_Record_Code__c + '|Application', testTransactionOrder.Id, null, 'Admission Fee', 'Application', 100.10, null, null));
		transactionLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(testTransactionOrder.reduivy__Sample_Record_Code__c + '|Deposit', testTransactionOrder.Id, null, 'Deposit', 'Deposit', 500.20, null, null));
        insert transactionLineItemList;

        //Delete transaction line item
        delete transactionLineItemList[0];

        //Undelete transaction line item
        Test.startTest();
        undelete transactionLineItemList[0];
        Test.stopTest();

        //Assert rollup was successful
        testTransactionOrder = [SELECT reduivy__Total_Amount__c FROM reduivy__Transaction_Order__c WHERE reduivy__Contact__c = :testContact.Id LIMIT 1];

        System.Assert.areEqual(600.30, testTransactionOrder.reduivy__Total_Amount__c);
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupSumDecimalInsert(){
        
        //Create trigger controller
        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(createTriggerControllerTransactionLineItem1());
        triggerControllerConfigs.add(createTriggerControllerTransactionLineItem2());
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerConfigs[0].reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigSUMCURRENCY = createCustomRollupConfigSUMDECIMAL();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigSUMCURRENCY);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigSUMCURRENCY.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerConfigs[0].reduivy__SObject__c, customRollupConfigsByParent);

        //Insert contact
        Contact testContact = new Contact(LastName= 'Test');
        insert testContact;

        //Insert transaction order
        reduivy__Transaction_Order__c testTransactionOrder = new reduivy__Transaction_Order__c(reduivy__Contact__c = testContact.Id);
        insert testTransactionOrder;

        //Create transaction line items
        List<reduivy__Transaction_Line_Item__c> transactionLineItemList = new List<reduivy__Transaction_Line_Item__c>();
        transactionLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(testTransactionOrder.reduivy__Sample_Record_Code__c + '|Application', testTransactionOrder.Id, null, 'Admission Fee', 'Application', 100.10, null, null));
		transactionLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(testTransactionOrder.reduivy__Sample_Record_Code__c + '|Deposit', testTransactionOrder.Id, null, 'Deposit', 'Deposit', 500.20, null, null));

        //Insert transaction line items
        Test.startTest();
        insert transactionLineItemList;
        Test.stopTest();

        //Assert rollup was successful
        testTransactionOrder = [SELECT reduivy__Total_Amount__c FROM reduivy__Transaction_Order__c WHERE reduivy__Contact__c = :testContact.Id LIMIT 1];

        System.Assert.areEqual(600.30, testTransactionOrder.reduivy__Total_Amount__c);
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupSumDecimalUpdate(){
        
        //Create trigger controller
        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(createTriggerControllerTransactionLineItem1());
        triggerControllerConfigs.add(createTriggerControllerTransactionLineItem2());
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerConfigs[0].reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigSUMCURRENCY = createCustomRollupConfigSUMDECIMAL();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigSUMCURRENCY);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigSUMCURRENCY.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerConfigs[0].reduivy__SObject__c, customRollupConfigsByParent);

        //Insert contact
        Contact testContact = new Contact(LastName= 'Test');
        insert testContact;

        //Insert transaction order
        reduivy__Transaction_Order__c testTransactionOrder = new reduivy__Transaction_Order__c(reduivy__Contact__c = testContact.Id);
        insert testTransactionOrder;

        //Insert transaction line items
        List<reduivy__Transaction_Line_Item__c> transactionLineItemList = new List<reduivy__Transaction_Line_Item__c>();
        transactionLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(testTransactionOrder.reduivy__Sample_Record_Code__c + '|Application', testTransactionOrder.Id, null, 'Admission Fee', 'Application', 100.10, null, null));
		transactionLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(testTransactionOrder.reduivy__Sample_Record_Code__c + '|Deposit', testTransactionOrder.Id, null, 'Deposit', 'Deposit', 500.20, null, null));

        insert transactionLineItemList;

        //Edit transaction line item
        transactionLineItemList[1].reduivy__Total_Amount__c = 50.30;

        //Update transaction line item
        Test.startTest();
        update transactionLineItemList[1];
        Test.stopTest();

        //Assert rollup was successful
        testTransactionOrder = [SELECT reduivy__Total_Amount__c FROM reduivy__Transaction_Order__c WHERE reduivy__Contact__c = :testContact.Id LIMIT 1];

        System.Assert.areEqual(150.40, testTransactionOrder.reduivy__Total_Amount__c);
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupSumDecimalDelete(){
        
        //Create trigger controller
        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(createTriggerControllerTransactionLineItem1());
        triggerControllerConfigs.add(createTriggerControllerTransactionLineItem2());
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerConfigs[0].reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigSUMCURRENCY = createCustomRollupConfigSUMDECIMAL();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigSUMCURRENCY);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigSUMCURRENCY.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerConfigs[0].reduivy__SObject__c, customRollupConfigsByParent);

        //Insert contact
        Contact testContact = new Contact(LastName= 'Test');
        insert testContact;

        //Insert transaction order
        reduivy__Transaction_Order__c testTransactionOrder = new reduivy__Transaction_Order__c(reduivy__Contact__c = testContact.Id);
        insert testTransactionOrder;

        //Insert transaction line items
        List<reduivy__Transaction_Line_Item__c> transactionLineItemList = new List<reduivy__Transaction_Line_Item__c>();
        transactionLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(testTransactionOrder.reduivy__Sample_Record_Code__c + '|Application', testTransactionOrder.Id, null, 'Admission Fee', 'Application', 100.10, null, null));
		transactionLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(testTransactionOrder.reduivy__Sample_Record_Code__c + '|Deposit', testTransactionOrder.Id, null, 'Deposit', 'Deposit', 500.20, null, null));

        insert transactionLineItemList;

        //Delete transaction line item
        Test.startTest();
        delete transactionLineItemList;
        Test.stopTest();

        //Assert rollup was successful
        testTransactionOrder = [SELECT reduivy__Total_Amount__c FROM reduivy__Transaction_Order__c WHERE reduivy__Contact__c = :testContact.Id LIMIT 1];

        System.Assert.areEqual(0, testTransactionOrder.reduivy__Total_Amount__c);
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupSumDecimalUndelete(){
        
        //Create trigger controller
        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(createTriggerControllerTransactionLineItem1());
        triggerControllerConfigs.add(createTriggerControllerTransactionLineItem2());
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerConfigs[0].reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigSUMCURRENCY = createCustomRollupConfigSUMDECIMAL();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigSUMCURRENCY);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigSUMCURRENCY.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerConfigs[0].reduivy__SObject__c, customRollupConfigsByParent);

        //Insert contact
        Contact testContact = new Contact(LastName= 'Test');
        insert testContact;

        //Insert transaction order
        reduivy__Transaction_Order__c testTransactionOrder = new reduivy__Transaction_Order__c(reduivy__Contact__c = testContact.Id);
        insert testTransactionOrder;

        //Insert transaction line items
        List<reduivy__Transaction_Line_Item__c> transactionLineItemList = new List<reduivy__Transaction_Line_Item__c>();
        transactionLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(testTransactionOrder.reduivy__Sample_Record_Code__c + '|Application', testTransactionOrder.Id, null, 'Admission Fee', 'Application', 100.10, null, null));
		transactionLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(testTransactionOrder.reduivy__Sample_Record_Code__c + '|Deposit', testTransactionOrder.Id, null, 'Deposit', 'Deposit', 500.20, null, null));

        insert transactionLineItemList;

        //Delete transaction line item
        delete transactionLineItemList[0];

        //Undelete transaction line item
        Test.startTest();
        undelete transactionLineItemList[0];
        Test.stopTest();

        //Assert rollup was successful
        testTransactionOrder = [SELECT reduivy__Total_Amount__c FROM reduivy__Transaction_Order__c WHERE reduivy__Contact__c = :testContact.Id LIMIT 1];

        System.Assert.areEqual(600.30, testTransactionOrder.reduivy__Total_Amount__c);
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupMinDecimalInsert(){
        
        //Create trigger controller
        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(createTriggerControllerTransactionLineItem1());
        triggerControllerConfigs.add(createTriggerControllerTransactionLineItem2());
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerConfigs[0].reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigSUMCURRENCY = createCustomRollupConfigMINDECIMAL();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigSUMCURRENCY);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigSUMCURRENCY.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerConfigs[0].reduivy__SObject__c, customRollupConfigsByParent);

        //Insert contact
        Contact testContact = new Contact(LastName= 'Test');
        insert testContact;

        //Insert transaction order
        reduivy__Transaction_Order__c testTransactionOrder = new reduivy__Transaction_Order__c(reduivy__Contact__c = testContact.Id);
        insert testTransactionOrder;

        //Create transaction line items
        List<reduivy__Transaction_Line_Item__c> transactionLineItemList = new List<reduivy__Transaction_Line_Item__c>();
        transactionLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(testTransactionOrder.reduivy__Sample_Record_Code__c + '|Application', testTransactionOrder.Id, null, 'Admission Fee', 'Application', 100.15, null, null));
		transactionLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(testTransactionOrder.reduivy__Sample_Record_Code__c + '|Deposit', testTransactionOrder.Id, null, 'Deposit', 'Deposit', 500.25, null, null));

        //Insert transaction line items
        Test.startTest();
        insert transactionLineItemList;
        Test.stopTest();

        //Assert rollup was successful
        testTransactionOrder = [SELECT reduivy__Total_Amount__c FROM reduivy__Transaction_Order__c WHERE reduivy__Contact__c = :testContact.Id LIMIT 1];

        System.Assert.areEqual(100.15, testTransactionOrder.reduivy__Total_Amount__c);
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupMinDecimalUpdate(){
        
        //Create trigger controller
        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(createTriggerControllerTransactionLineItem1());
        triggerControllerConfigs.add(createTriggerControllerTransactionLineItem2());
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerConfigs[0].reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigSUMCURRENCY = createCustomRollupConfigMINDECIMAL();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigSUMCURRENCY);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigSUMCURRENCY.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerConfigs[0].reduivy__SObject__c, customRollupConfigsByParent);

        //Insert contact
        Contact testContact = new Contact(LastName= 'Test');
        insert testContact;

        //Insert transaction order
        reduivy__Transaction_Order__c testTransactionOrder = new reduivy__Transaction_Order__c(reduivy__Contact__c = testContact.Id);
        insert testTransactionOrder;

        //Insert transaction line items
        List<reduivy__Transaction_Line_Item__c> transactionLineItemList = new List<reduivy__Transaction_Line_Item__c>();
        transactionLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(testTransactionOrder.reduivy__Sample_Record_Code__c + '|Application', testTransactionOrder.Id, null, 'Admission Fee', 'Application', 100.15, null, null));
		transactionLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(testTransactionOrder.reduivy__Sample_Record_Code__c + '|Deposit', testTransactionOrder.Id, null, 'Deposit', 'Deposit', 500.25, null, null));

        insert transactionLineItemList;

        //Edit transaction line item
        transactionLineItemList[1].reduivy__Total_Amount__c = 50.35;

        //Update transaction line item
        Test.startTest();
        update transactionLineItemList[1];
        Test.stopTest();

        //Assert rollup was successful
        testTransactionOrder = [SELECT reduivy__Total_Amount__c FROM reduivy__Transaction_Order__c WHERE reduivy__Contact__c = :testContact.Id LIMIT 1];

        System.Assert.areEqual(50.35, testTransactionOrder.reduivy__Total_Amount__c);
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupMinDecimalDelete(){
        
        //Create trigger controller
        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(createTriggerControllerTransactionLineItem1());
        triggerControllerConfigs.add(createTriggerControllerTransactionLineItem2());
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerConfigs[0].reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigSUMCURRENCY = createCustomRollupConfigMINDECIMAL();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigSUMCURRENCY);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigSUMCURRENCY.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerConfigs[0].reduivy__SObject__c, customRollupConfigsByParent);

        //Insert contact
        Contact testContact = new Contact(LastName= 'Test');
        insert testContact;

        //Insert transaction order
        reduivy__Transaction_Order__c testTransactionOrder = new reduivy__Transaction_Order__c(reduivy__Contact__c = testContact.Id);
        insert testTransactionOrder;

        //Insert transaction line items
        List<reduivy__Transaction_Line_Item__c> transactionLineItemList = new List<reduivy__Transaction_Line_Item__c>();
        transactionLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(testTransactionOrder.reduivy__Sample_Record_Code__c + '|Application', testTransactionOrder.Id, null, 'Admission Fee', 'Application', 100.15, null, null));
		transactionLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(testTransactionOrder.reduivy__Sample_Record_Code__c + '|Deposit', testTransactionOrder.Id, null, 'Deposit', 'Deposit', 500.25, null, null));

        insert transactionLineItemList;

        //Delete transaction line item
        Test.startTest();
        delete transactionLineItemList;
        Test.stopTest();

        //Assert rollup was successful
        testTransactionOrder = [SELECT reduivy__Total_Amount__c FROM reduivy__Transaction_Order__c WHERE reduivy__Contact__c = :testContact.Id LIMIT 1];

        System.Assert.areEqual(0, testTransactionOrder.reduivy__Total_Amount__c);
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupMinDecimalUndelete(){
        
        //Create trigger controller
        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(createTriggerControllerTransactionLineItem1());
        triggerControllerConfigs.add(createTriggerControllerTransactionLineItem2());
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerConfigs[0].reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigSUMCURRENCY = createCustomRollupConfigMINDECIMAL();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigSUMCURRENCY);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigSUMCURRENCY.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerConfigs[0].reduivy__SObject__c, customRollupConfigsByParent);

        //Insert contact
        Contact testContact = new Contact(LastName= 'Test');
        insert testContact;

        //Insert transaction order
        reduivy__Transaction_Order__c testTransactionOrder = new reduivy__Transaction_Order__c(reduivy__Contact__c = testContact.Id);
        insert testTransactionOrder;

        //Insert transaction line items
        List<reduivy__Transaction_Line_Item__c> transactionLineItemList = new List<reduivy__Transaction_Line_Item__c>();
        transactionLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(testTransactionOrder.reduivy__Sample_Record_Code__c + '|Application', testTransactionOrder.Id, null, 'Admission Fee', 'Application', 100.15, null, null));
		transactionLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(testTransactionOrder.reduivy__Sample_Record_Code__c + '|Deposit', testTransactionOrder.Id, null, 'Deposit', 'Deposit', 500.25, null, null));

        insert transactionLineItemList;

        //Delete transaction line item
        delete transactionLineItemList[0];

        //Undelete transaction line item
        Test.startTest();
        undelete transactionLineItemList[0];
        Test.stopTest();

        //Assert rollup was successful
        testTransactionOrder = [SELECT reduivy__Total_Amount__c FROM reduivy__Transaction_Order__c WHERE reduivy__Contact__c = :testContact.Id LIMIT 1];

        System.Assert.areEqual(100.15, testTransactionOrder.reduivy__Total_Amount__c);
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupMaxDecimalInsert(){
        
        //Create trigger controller
        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(createTriggerControllerTransactionLineItem1());
        triggerControllerConfigs.add(createTriggerControllerTransactionLineItem2());
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerConfigs[0].reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigSUMCURRENCY = createCustomRollupConfigMAXDECIMAL();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigSUMCURRENCY);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigSUMCURRENCY.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerConfigs[0].reduivy__SObject__c, customRollupConfigsByParent);

        //Insert contact
        Contact testContact = new Contact(LastName= 'Test');
        insert testContact;

        //Insert transaction order
        reduivy__Transaction_Order__c testTransactionOrder = new reduivy__Transaction_Order__c(reduivy__Contact__c = testContact.Id);
        insert testTransactionOrder;

        //Create transaction line items
        List<reduivy__Transaction_Line_Item__c> transactionLineItemList = new List<reduivy__Transaction_Line_Item__c>();
        transactionLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(testTransactionOrder.reduivy__Sample_Record_Code__c + '|Application', testTransactionOrder.Id, null, 'Admission Fee', 'Application', 100.15, null, null));
		transactionLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(testTransactionOrder.reduivy__Sample_Record_Code__c + '|Deposit', testTransactionOrder.Id, null, 'Deposit', 'Deposit', 500.25, null, null));

        //Insert transaction line items
        Test.startTest();
        insert transactionLineItemList;
        Test.stopTest();

        //Assert rollup was successful
        testTransactionOrder = [SELECT reduivy__Total_Amount__c FROM reduivy__Transaction_Order__c WHERE reduivy__Contact__c = :testContact.Id LIMIT 1];

        System.Assert.areEqual(500.25, testTransactionOrder.reduivy__Total_Amount__c);
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupMaxDecimalUpdate(){
        
        //Create trigger controller
        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(createTriggerControllerTransactionLineItem1());
        triggerControllerConfigs.add(createTriggerControllerTransactionLineItem2());
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerConfigs[0].reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigSUMCURRENCY = createCustomRollupConfigMAXDECIMAL();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigSUMCURRENCY);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigSUMCURRENCY.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerConfigs[0].reduivy__SObject__c, customRollupConfigsByParent);

        //Insert contact
        Contact testContact = new Contact(LastName= 'Test');
        insert testContact;

        //Insert transaction order
        reduivy__Transaction_Order__c testTransactionOrder = new reduivy__Transaction_Order__c(reduivy__Contact__c = testContact.Id);
        insert testTransactionOrder;

        //Insert transaction line items
        List<reduivy__Transaction_Line_Item__c> transactionLineItemList = new List<reduivy__Transaction_Line_Item__c>();
        transactionLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(testTransactionOrder.reduivy__Sample_Record_Code__c + '|Application', testTransactionOrder.Id, null, 'Admission Fee', 'Application', 100.15, null, null));
		transactionLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(testTransactionOrder.reduivy__Sample_Record_Code__c + '|Deposit', testTransactionOrder.Id, null, 'Deposit', 'Deposit', 500.25, null, null));

        insert transactionLineItemList;

        //Edit transaction line item
        transactionLineItemList[1].reduivy__Total_Amount__c = 50.35;

        //Update transaction line item
        Test.startTest();
        update transactionLineItemList[1];
        Test.stopTest();

        //Assert rollup was successful
        testTransactionOrder = [SELECT reduivy__Total_Amount__c FROM reduivy__Transaction_Order__c WHERE reduivy__Contact__c = :testContact.Id LIMIT 1];

        System.Assert.areEqual(100.15, testTransactionOrder.reduivy__Total_Amount__c);
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupMaxDecimalDelete(){
        
        //Create trigger controller
        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(createTriggerControllerTransactionLineItem1());
        triggerControllerConfigs.add(createTriggerControllerTransactionLineItem2());
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerConfigs[0].reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigSUMCURRENCY = createCustomRollupConfigMAXDECIMAL();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigSUMCURRENCY);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigSUMCURRENCY.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerConfigs[0].reduivy__SObject__c, customRollupConfigsByParent);

        //Insert contact
        Contact testContact = new Contact(LastName= 'Test');
        insert testContact;

        //Insert transaction order
        reduivy__Transaction_Order__c testTransactionOrder = new reduivy__Transaction_Order__c(reduivy__Contact__c = testContact.Id);
        insert testTransactionOrder;

        //Insert transaction line items
        List<reduivy__Transaction_Line_Item__c> transactionLineItemList = new List<reduivy__Transaction_Line_Item__c>();
        transactionLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(testTransactionOrder.reduivy__Sample_Record_Code__c + '|Application', testTransactionOrder.Id, null, 'Admission Fee', 'Application', 100.15, null, null));
		transactionLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(testTransactionOrder.reduivy__Sample_Record_Code__c + '|Deposit', testTransactionOrder.Id, null, 'Deposit', 'Deposit', 500.25, null, null));

        insert transactionLineItemList;

        //Delete transaction line item
        Test.startTest();
        delete transactionLineItemList;
        Test.stopTest();

        //Assert rollup was successful
        testTransactionOrder = [SELECT reduivy__Total_Amount__c FROM reduivy__Transaction_Order__c WHERE reduivy__Contact__c = :testContact.Id LIMIT 1];

        System.Assert.areEqual(0, testTransactionOrder.reduivy__Total_Amount__c);
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupMaxDecimalUndelete(){
        
        //Create trigger controller
        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(createTriggerControllerTransactionLineItem1());
        triggerControllerConfigs.add(createTriggerControllerTransactionLineItem2());
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerConfigs[0].reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigSUMCURRENCY = createCustomRollupConfigMAXDECIMAL();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigSUMCURRENCY);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigSUMCURRENCY.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerConfigs[0].reduivy__SObject__c, customRollupConfigsByParent);

        //Insert contact
        Contact testContact = new Contact(LastName= 'Test');
        insert testContact;

        //Insert transaction order
        reduivy__Transaction_Order__c testTransactionOrder = new reduivy__Transaction_Order__c(reduivy__Contact__c = testContact.Id);
        insert testTransactionOrder;

        //Insert transaction line items
        List<reduivy__Transaction_Line_Item__c> transactionLineItemList = new List<reduivy__Transaction_Line_Item__c>();
        transactionLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(testTransactionOrder.reduivy__Sample_Record_Code__c + '|Application', testTransactionOrder.Id, null, 'Admission Fee', 'Application', 100.15, null, null));
		transactionLineItemList.add(REDU_TestData_UTIL.newTransactionOrderLine(testTransactionOrder.reduivy__Sample_Record_Code__c + '|Deposit', testTransactionOrder.Id, null, 'Deposit', 'Deposit', 500.25, null, null));

        insert transactionLineItemList;

        //Delete transaction line item
        delete transactionLineItemList[0];

        //Undelete transaction line item
        Test.startTest();
        undelete transactionLineItemList[0];
        Test.stopTest();

        //Assert rollup was successful
        testTransactionOrder = [SELECT reduivy__Total_Amount__c FROM reduivy__Transaction_Order__c WHERE reduivy__Contact__c = :testContact.Id LIMIT 1];

        System.Assert.areEqual(500.25, testTransactionOrder.reduivy__Total_Amount__c);
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupCountInsertFilterLogicMet(){
        
        //Create trigger controller
        reduivy__Trigger_Controller__mdt triggerControllerContact = createTriggerControllerContact();

        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(triggerControllerContact);
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerContact.reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigCOUNTFILTERLOGIC = createCustomRollupConfigCOUNTFILTERLOGIC();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigCOUNTFILTERLOGIC);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigCOUNTFILTERLOGIC.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerContact.reduivy__SObject__c, customRollupConfigsByParent);

        //Insert account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        //Create contacts
        List<Contact> contactList = new List<Contact>();        
        Contact testContact1 = new Contact(AccountId = testAccount.Id, LastName = 'Test1', Birthdate = Date.today() + 7);
        Contact testContact2 = new Contact(AccountId = testAccount.Id, LastName = 'Test2', Birthdate = Date.today());
        contactList.add(testContact1);
        contactList.add(testContact2);

        //Insert contacts
        Test.startTest();
        insert contactList;
        Test.stopTest();

        //Assert rollup was successful
        testAccount = [SELECT NumberOfEmployees FROM Account WHERE Name = 'Test Account' LIMIT 1];

        System.Assert.areEqual(1, testAccount.NumberOfEmployees);
    }

    /**
     * @description Test custom rollup
     */
    @IsTest
    static void testCustomRollupCountInsertFilterLogicNotMet(){
        
        //Create trigger controller
        reduivy__Trigger_Controller__mdt triggerControllerContact = createTriggerControllerContact();

        List<reduivy__Trigger_Controller__mdt> triggerControllerConfigs = new List<reduivy__Trigger_Controller__mdt>();
        triggerControllerConfigs.add(triggerControllerContact);
        Map<String, List<reduivy__Trigger_Controller__mdt>> tcConfigsByObject = new Map<String, List<reduivy__Trigger_Controller__mdt>>();
        tcConfigsByObject.put(triggerControllerContact.reduivy__SObject__c, triggerControllerConfigs);

        REDU_TriggerController.triggerControllerConfigs = tcConfigsByObject;
        
        //Create custom rollup configs
        reduivy__Custom_Rollup_Config__mdt customRollupConfigCOUNTFILTERLOGIC = createCustomRollupConfigCOUNTFILTERLOGIC();
        
        List<reduivy__Custom_Rollup_Config__mdt> customRollupConfigs = new List<reduivy__Custom_Rollup_Config__mdt>();
        customRollupConfigs.add(customRollupConfigCOUNTFILTERLOGIC);
        Map<String, List<reduivy__Custom_Rollup_Config__mdt>> customRollupConfigsByParent = new Map<String, List<reduivy__Custom_Rollup_Config__mdt>>();
        customRollupConfigsByParent.put(customRollupConfigCOUNTFILTERLOGIC.reduivy__Master_Object_Name__c, customRollupConfigs);

        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject = new Map<String, Map<String, List<reduivy__Custom_Rollup_Config__mdt>>>();
        REDU_CustomRollup_UTIL.rollupConfigsByChildAndParentObject.put(triggerControllerContact.reduivy__SObject__c, customRollupConfigsByParent);

        //Insert account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        //Create contacts
        List<Contact> contactList = new List<Contact>();        
        Contact testContact1 = new Contact(AccountId = testAccount.Id, LastName = 'Test1', Birthdate = Date.today() - 7);
        Contact testContact2 = new Contact(AccountId = testAccount.Id, LastName = 'Test2', Birthdate = Date.today());
        contactList.add(testContact1);
        contactList.add(testContact2);

        //Insert contacts
        Test.startTest();
        insert contactList;
        Test.stopTest();

        //Assert rollup was successful
        testAccount = [SELECT NumberOfEmployees FROM Account WHERE Name = 'Test Account' LIMIT 1];

        System.Assert.areEqual(0, testAccount.NumberOfEmployees);
    }

    public static reduivy__Trigger_Controller__mdt createTriggerControllerContact() {
        reduivy__Trigger_Controller__mdt triggerControllerContact = new reduivy__Trigger_Controller__mdt();
        triggerControllerContact.reduivy__Active__c = true;
        triggerControllerContact.reduivy__After_Delete__c = true;
        triggerControllerContact.reduivy__After_Insert__c = true;
        triggerControllerContact.reduivy__After_Undelete__c = true;
        triggerControllerContact.reduivy__After_Update__c = true;
        triggerControllerContact.reduivy__Before_Delete__c = false;
        triggerControllerContact.reduivy__Before_Insert__c = false;
        triggerControllerContact.reduivy__Before_Update__c = false;
        triggerControllerContact.reduivy__Class_Name__c = 'SOBJ_CustomRollup_EXE';
        triggerControllerContact.reduivy__Record_Exclusion_Field__c = null;
        triggerControllerContact.reduivy__Record_Exclusion_Value__c = null;
        triggerControllerContact.reduivy__Sequence__c = 1.0;
        triggerControllerContact.reduivy__SObject__c = 'Contact';
        triggerControllerContact.reduivy__User_Exclusion_Field__c = null;
        triggerControllerContact.reduivy__User_Exclusion_Value__c = null;
        return triggerControllerContact;
    }

    public static reduivy__Trigger_Controller__mdt createTriggerControllerAccount() {
        reduivy__Trigger_Controller__mdt triggerControllerAccount = new reduivy__Trigger_Controller__mdt();
        triggerControllerAccount.reduivy__Active__c = true;
        triggerControllerAccount.reduivy__After_Delete__c = true;
        triggerControllerAccount.reduivy__After_Insert__c = true;
        triggerControllerAccount.reduivy__After_Undelete__c = true;
        triggerControllerAccount.reduivy__After_Update__c = true;
        triggerControllerAccount.reduivy__Before_Delete__c = false;
        triggerControllerAccount.reduivy__Before_Insert__c = false;
        triggerControllerAccount.reduivy__Before_Update__c = false;
        triggerControllerAccount.reduivy__Class_Name__c = 'SOBJ_CustomRollup_EXE';
        triggerControllerAccount.reduivy__Record_Exclusion_Field__c = null;
        triggerControllerAccount.reduivy__Record_Exclusion_Value__c = null;
        triggerControllerAccount.reduivy__Sequence__c = 1.0;
        triggerControllerAccount.reduivy__SObject__c = 'Account';
        triggerControllerAccount.reduivy__User_Exclusion_Field__c = null;
        triggerControllerAccount.reduivy__User_Exclusion_Value__c = null;
        return triggerControllerAccount;
    }

    public static reduivy__Trigger_Controller__mdt createTriggerControllerTransactionLineItem1() {
        reduivy__Trigger_Controller__mdt triggerControllerTransactionLineItem = new reduivy__Trigger_Controller__mdt();
        triggerControllerTransactionLineItem.reduivy__Active__c = true;
        triggerControllerTransactionLineItem.reduivy__After_Delete__c = true;
        triggerControllerTransactionLineItem.reduivy__After_Insert__c = true;
        triggerControllerTransactionLineItem.reduivy__After_Undelete__c = true;
        triggerControllerTransactionLineItem.reduivy__After_Update__c = true;
        triggerControllerTransactionLineItem.reduivy__Before_Delete__c = false;
        triggerControllerTransactionLineItem.reduivy__Before_Insert__c = false;
        triggerControllerTransactionLineItem.reduivy__Before_Update__c = false;
        triggerControllerTransactionLineItem.reduivy__Class_Name__c = 'SOBJ_CustomRollup_EXE';
        triggerControllerTransactionLineItem.reduivy__Record_Exclusion_Field__c = null;
        triggerControllerTransactionLineItem.reduivy__Record_Exclusion_Value__c = null;
        triggerControllerTransactionLineItem.reduivy__Sequence__c = 1.0;
        triggerControllerTransactionLineItem.reduivy__SObject__c = 'reduivy__Transaction_Line_Item__c';
        triggerControllerTransactionLineItem.reduivy__User_Exclusion_Field__c = null;
        triggerControllerTransactionLineItem.reduivy__User_Exclusion_Value__c = null;
        return triggerControllerTransactionLineItem;
    }

    public static reduivy__Trigger_Controller__mdt createTriggerControllerTransactionLineItem2() {
        reduivy__Trigger_Controller__mdt triggerControllerTransactionLineItem = new reduivy__Trigger_Controller__mdt();
        triggerControllerTransactionLineItem.reduivy__Active__c = true;
        triggerControllerTransactionLineItem.reduivy__After_Delete__c = false;
        triggerControllerTransactionLineItem.reduivy__After_Insert__c = false;
        triggerControllerTransactionLineItem.reduivy__After_Undelete__c = false;
        triggerControllerTransactionLineItem.reduivy__After_Update__c = false;
        triggerControllerTransactionLineItem.reduivy__Before_Delete__c = false;
        triggerControllerTransactionLineItem.reduivy__Before_Insert__c = true;
        triggerControllerTransactionLineItem.reduivy__Before_Update__c = true;
        triggerControllerTransactionLineItem.reduivy__Class_Name__c = 'TRL_TotalAmountCalc_EXE';
        triggerControllerTransactionLineItem.reduivy__Record_Exclusion_Field__c = null;
        triggerControllerTransactionLineItem.reduivy__Record_Exclusion_Value__c = null;
        triggerControllerTransactionLineItem.reduivy__Sequence__c = 1.0;
        triggerControllerTransactionLineItem.reduivy__SObject__c = 'reduivy__Transaction_Line_Item__c';
        triggerControllerTransactionLineItem.reduivy__User_Exclusion_Field__c = null;
        triggerControllerTransactionLineItem.reduivy__User_Exclusion_Value__c = null;
        return triggerControllerTransactionLineItem;
    }

    public static reduivy__Custom_Rollup_Config__mdt createCustomRollupConfigCOUNT() {
        reduivy__Custom_Rollup_Config__mdt customRollupConfig = new reduivy__Custom_Rollup_Config__mdt();
        customRollupConfig.DeveloperName = 'testCustomRollupCOUNT';
        customRollupConfig.reduivy__Master_Object_Name__c = 'Account';
        customRollupConfig.reduivy__Master_Object_Field_Name__c = 'NumberOfEmployees';
        customRollupConfig.reduivy__Child_Object_Name__c = 'Contact';
        customRollupConfig.reduivy__Child_Object_Field_Name__c = 'Id';
        customRollupConfig.reduivy__Rollup_Type__c = 'COUNT';
        customRollupConfig.reduivy__Field_Type__c = 'INTEGER';
        customRollupConfig.reduivy__Filter_Criteria_1__c = null;
        customRollupConfig.reduivy__Filter_Criteria_2__c = null;
        customRollupConfig.reduivy__Filter_Criteria_3__c = null;
        customRollupConfig.reduivy__Filter_Criteria_4__c = null;
        customRollupConfig.reduivy__Filter_Criteria_5__c = null;
        customRollupConfig.reduivy__Parent_Relationship_Field__c = 'AccountId';
        customRollupConfig.reduivy__Active__c = true;
        customRollupConfig.reduivy__Sequence2__c = 1;
        return customRollupConfig;
    }

    public static reduivy__Custom_Rollup_Config__mdt createCustomRollupConfigCOUNTFILTERLOGIC() {
        reduivy__Custom_Rollup_Config__mdt customRollupConfig = new reduivy__Custom_Rollup_Config__mdt();
        customRollupConfig.DeveloperName = 'testCustomRollupCOUNT';
        customRollupConfig.reduivy__Master_Object_Name__c = 'Account';
        customRollupConfig.reduivy__Master_Object_Field_Name__c = 'NumberOfEmployees';
        customRollupConfig.reduivy__Child_Object_Name__c = 'Contact';
        customRollupConfig.reduivy__Child_Object_Field_Name__c = 'Id';
        customRollupConfig.reduivy__Rollup_Type__c = 'COUNT';
        customRollupConfig.reduivy__Field_Type__c = 'INTEGER';
        customRollupConfig.reduivy__Filter_Logic__c = '{0} AND {1}';
        customRollupConfig.reduivy__Filter_Criteria_1__c = 'LastName = \'Test1\'';
        customRollupConfig.reduivy__Filter_Criteria_2__c = 'Birthdate > TODAY';
        customRollupConfig.reduivy__Filter_Criteria_3__c = null;
        customRollupConfig.reduivy__Filter_Criteria_4__c = null;
        customRollupConfig.reduivy__Filter_Criteria_5__c = null;
        customRollupConfig.reduivy__Parent_Relationship_Field__c = 'AccountId';
        customRollupConfig.reduivy__Active__c = true;
        customRollupConfig.reduivy__Sequence2__c = 1;
        return customRollupConfig;
    }

    public static reduivy__Custom_Rollup_Config__mdt createCustomRollupConfigMINNUMERIC() {
        reduivy__Custom_Rollup_Config__mdt customRollupConfig = new reduivy__Custom_Rollup_Config__mdt();
        customRollupConfig.DeveloperName = 'testCustomRollupMINNUMERIC';
        customRollupConfig.reduivy__Master_Object_Name__c = 'Account';
        customRollupConfig.reduivy__Master_Object_Field_Name__c = 'NumberOfEmployees';
        customRollupConfig.reduivy__Child_Object_Name__c = 'Account';
        customRollupConfig.reduivy__Child_Object_Field_Name__c = 'NumberOfEmployees';
        customRollupConfig.reduivy__Rollup_Type__c = 'MIN';
        customRollupConfig.reduivy__Field_Type__c = 'INTEGER';
        customRollupConfig.reduivy__Filter_Criteria_1__c = null;
        customRollupConfig.reduivy__Filter_Criteria_2__c = null;
        customRollupConfig.reduivy__Filter_Criteria_3__c = null;
        customRollupConfig.reduivy__Filter_Criteria_4__c = null;
        customRollupConfig.reduivy__Filter_Criteria_5__c = null;
        customRollupConfig.reduivy__Parent_Relationship_Field__c = 'ParentId';
        customRollupConfig.reduivy__Active__c = true;
        customRollupConfig.reduivy__Sequence2__c = 1;
        return customRollupConfig;
    }

    public static reduivy__Custom_Rollup_Config__mdt createCustomRollupConfigMAXNUMERIC() {
        reduivy__Custom_Rollup_Config__mdt customRollupConfig = new reduivy__Custom_Rollup_Config__mdt();
        customRollupConfig.DeveloperName = 'testCustomRollupMAXNUMERIC';
        customRollupConfig.reduivy__Master_Object_Name__c = 'Account';
        customRollupConfig.reduivy__Master_Object_Field_Name__c = 'NumberOfEmployees';
        customRollupConfig.reduivy__Child_Object_Name__c = 'Account';
        customRollupConfig.reduivy__Child_Object_Field_Name__c = 'NumberOfEmployees';
        customRollupConfig.reduivy__Rollup_Type__c = 'MAX';
        customRollupConfig.reduivy__Field_Type__c = 'INTEGER';
        customRollupConfig.reduivy__Filter_Criteria_1__c = null;
        customRollupConfig.reduivy__Filter_Criteria_2__c = null;
        customRollupConfig.reduivy__Filter_Criteria_3__c = null;
        customRollupConfig.reduivy__Filter_Criteria_4__c = null;
        customRollupConfig.reduivy__Filter_Criteria_5__c = null;
        customRollupConfig.reduivy__Parent_Relationship_Field__c = 'ParentId';
        customRollupConfig.reduivy__Active__c = true;
        customRollupConfig.reduivy__Sequence2__c = 1;
        return customRollupConfig;
    }

    public static reduivy__Custom_Rollup_Config__mdt createCustomRollupConfigMINDATE() {
        reduivy__Custom_Rollup_Config__mdt customRollupConfig = new reduivy__Custom_Rollup_Config__mdt();
        customRollupConfig.DeveloperName = 'testCustomRollupMINDATE';
        customRollupConfig.reduivy__Master_Object_Name__c = 'Contact';
        customRollupConfig.reduivy__Master_Object_Field_Name__c = 'Birthdate';
        customRollupConfig.reduivy__Child_Object_Name__c = 'Contact';
        customRollupConfig.reduivy__Child_Object_Field_Name__c = 'Birthdate';
        customRollupConfig.reduivy__Rollup_Type__c = 'MIN';
        customRollupConfig.reduivy__Field_Type__c = 'DATE';
        customRollupConfig.reduivy__Filter_Criteria_1__c = null;
        customRollupConfig.reduivy__Filter_Criteria_2__c = null;
        customRollupConfig.reduivy__Filter_Criteria_3__c = null;
        customRollupConfig.reduivy__Filter_Criteria_4__c = null;
        customRollupConfig.reduivy__Filter_Criteria_5__c = null;
        customRollupConfig.reduivy__Parent_Relationship_Field__c = 'ReportsToId';
        customRollupConfig.reduivy__Active__c = true;
        customRollupConfig.reduivy__Sequence2__c = 1;
        return customRollupConfig;
    }
    
    public static reduivy__Custom_Rollup_Config__mdt createCustomRollupConfigMAXDATE() {
        reduivy__Custom_Rollup_Config__mdt customRollupConfig = new reduivy__Custom_Rollup_Config__mdt();
        customRollupConfig.DeveloperName = 'testCustomRollupMAXDATE';
        customRollupConfig.reduivy__Master_Object_Name__c = 'Contact';
        customRollupConfig.reduivy__Master_Object_Field_Name__c = 'Birthdate';
        customRollupConfig.reduivy__Child_Object_Name__c = 'Contact';
        customRollupConfig.reduivy__Child_Object_Field_Name__c = 'Birthdate';
        customRollupConfig.reduivy__Rollup_Type__c = 'MAX';
        customRollupConfig.reduivy__Field_Type__c = 'DATE';
        customRollupConfig.reduivy__Filter_Criteria_1__c = null;
        customRollupConfig.reduivy__Filter_Criteria_2__c = null;
        customRollupConfig.reduivy__Filter_Criteria_3__c = null;
        customRollupConfig.reduivy__Filter_Criteria_4__c = null;
        customRollupConfig.reduivy__Filter_Criteria_5__c = null;
        customRollupConfig.reduivy__Parent_Relationship_Field__c = 'ReportsToId';
        customRollupConfig.reduivy__Active__c = true;
        customRollupConfig.reduivy__Sequence2__c = 1;
        return customRollupConfig;
    }

    public static reduivy__Custom_Rollup_Config__mdt createCustomRollupConfigMINCURRENCY() {
        reduivy__Custom_Rollup_Config__mdt customRollupConfig = new reduivy__Custom_Rollup_Config__mdt();
        customRollupConfig.DeveloperName = 'testCustomRollupMINCURRENCY';
        customRollupConfig.reduivy__Master_Object_Name__c = 'reduivy__Transaction_Order__c';
        customRollupConfig.reduivy__Master_Object_Field_Name__c = 'reduivy__Total_Amount__c';
        customRollupConfig.reduivy__Child_Object_Name__c = 'reduivy__Transaction_Line_Item__c';
        customRollupConfig.reduivy__Child_Object_Field_Name__c = 'reduivy__Total_Amount__c';
        customRollupConfig.reduivy__Rollup_Type__c = 'MIN';
        customRollupConfig.reduivy__Field_Type__c = 'CURRENCY';
        customRollupConfig.reduivy__Filter_Criteria_1__c = null;
        customRollupConfig.reduivy__Filter_Criteria_2__c = null;
        customRollupConfig.reduivy__Filter_Criteria_3__c = null;
        customRollupConfig.reduivy__Filter_Criteria_4__c = null;
        customRollupConfig.reduivy__Filter_Criteria_5__c = null;
        customRollupConfig.reduivy__Parent_Relationship_Field__c = 'reduivy__Transaction_Order__c';
        customRollupConfig.reduivy__Active__c = true;
        customRollupConfig.reduivy__Sequence2__c = 1;
        return customRollupConfig;
    }
    
    public static reduivy__Custom_Rollup_Config__mdt createCustomRollupConfigMAXCURRENCY() {
        reduivy__Custom_Rollup_Config__mdt customRollupConfig = new reduivy__Custom_Rollup_Config__mdt();
        customRollupConfig.DeveloperName = 'testCustomRollupMAXCURRENCY';
        customRollupConfig.reduivy__Master_Object_Name__c = 'reduivy__Transaction_Order__c';
        customRollupConfig.reduivy__Master_Object_Field_Name__c = 'reduivy__Total_Amount__c';
        customRollupConfig.reduivy__Child_Object_Name__c = 'reduivy__Transaction_Line_Item__c';
        customRollupConfig.reduivy__Child_Object_Field_Name__c = 'reduivy__Total_Amount__c';
        customRollupConfig.reduivy__Rollup_Type__c = 'MAX';
        customRollupConfig.reduivy__Field_Type__c = 'CURRENCY';
        customRollupConfig.reduivy__Filter_Criteria_1__c = null;
        customRollupConfig.reduivy__Filter_Criteria_2__c = null;
        customRollupConfig.reduivy__Filter_Criteria_3__c = null;
        customRollupConfig.reduivy__Filter_Criteria_4__c = null;
        customRollupConfig.reduivy__Filter_Criteria_5__c = null;
        customRollupConfig.reduivy__Parent_Relationship_Field__c = 'reduivy__Transaction_Order__c';
        customRollupConfig.reduivy__Active__c = true;
        customRollupConfig.reduivy__Sequence2__c = 1;
        return customRollupConfig;
    }
    
    public static reduivy__Custom_Rollup_Config__mdt createCustomRollupConfigSUMNUMERIC() {
        reduivy__Custom_Rollup_Config__mdt customRollupConfig = new reduivy__Custom_Rollup_Config__mdt();
        customRollupConfig.DeveloperName = 'testCustomRollupSumNumeric';
        customRollupConfig.reduivy__Master_Object_Name__c = 'Account';
        customRollupConfig.reduivy__Master_Object_Field_Name__c = 'NumberOfEmployees';
        customRollupConfig.reduivy__Child_Object_Name__c = 'Account';
        customRollupConfig.reduivy__Child_Object_Field_Name__c = 'NumberOfEmployees';
        customRollupConfig.reduivy__Rollup_Type__c = 'SUM';
        customRollupConfig.reduivy__Field_Type__c = 'INTEGER';
        customRollupConfig.reduivy__Filter_Criteria_1__c = null;
        customRollupConfig.reduivy__Filter_Criteria_2__c = null;
        customRollupConfig.reduivy__Filter_Criteria_3__c = null;
        customRollupConfig.reduivy__Filter_Criteria_4__c = null;
        customRollupConfig.reduivy__Filter_Criteria_5__c = null;
        customRollupConfig.reduivy__Parent_Relationship_Field__c = 'ParentId';
        customRollupConfig.reduivy__Active__c = true;
        customRollupConfig.reduivy__Sequence2__c = 1;
        return customRollupConfig;
    }

    public static reduivy__Custom_Rollup_Config__mdt createCustomRollupConfigSUMCURRENCY() {
        reduivy__Custom_Rollup_Config__mdt customRollupConfig = new reduivy__Custom_Rollup_Config__mdt();
        customRollupConfig.DeveloperName = 'testCustomRollupSumNumericCURRENCY';
        customRollupConfig.reduivy__Master_Object_Name__c = 'reduivy__Transaction_Order__c';
        customRollupConfig.reduivy__Master_Object_Field_Name__c = 'reduivy__Total_Amount__c';
        customRollupConfig.reduivy__Child_Object_Name__c = 'reduivy__Transaction_Line_Item__c';
        customRollupConfig.reduivy__Child_Object_Field_Name__c = 'reduivy__Total_Amount__c';
        customRollupConfig.reduivy__Rollup_Type__c = 'SUM';
        customRollupConfig.reduivy__Field_Type__c = 'CURRENCY';
        customRollupConfig.reduivy__Filter_Criteria_1__c = null;
        customRollupConfig.reduivy__Filter_Criteria_2__c = null;
        customRollupConfig.reduivy__Filter_Criteria_3__c = null;
        customRollupConfig.reduivy__Filter_Criteria_4__c = null;
        customRollupConfig.reduivy__Filter_Criteria_5__c = null;
        customRollupConfig.reduivy__Parent_Relationship_Field__c = 'reduivy__Transaction_Order__c';
        customRollupConfig.reduivy__Active__c = true;
        customRollupConfig.reduivy__Sequence2__c = 1;
        return customRollupConfig;
    }

    public static reduivy__Custom_Rollup_Config__mdt createCustomRollupConfigSUMDECIMAL() {
        reduivy__Custom_Rollup_Config__mdt customRollupConfig = new reduivy__Custom_Rollup_Config__mdt();
        customRollupConfig.DeveloperName = 'testCustomRollupSumNumericCURRENCY';
        customRollupConfig.reduivy__Master_Object_Name__c = 'reduivy__Transaction_Order__c';
        customRollupConfig.reduivy__Master_Object_Field_Name__c = 'reduivy__Total_Amount__c';
        customRollupConfig.reduivy__Child_Object_Name__c = 'reduivy__Transaction_Line_Item__c';
        customRollupConfig.reduivy__Child_Object_Field_Name__c = 'reduivy__Total_Amount__c';
        customRollupConfig.reduivy__Rollup_Type__c = 'SUM';
        customRollupConfig.reduivy__Field_Type__c = 'DECIMAL';
        customRollupConfig.reduivy__Filter_Criteria_1__c = null;
        customRollupConfig.reduivy__Filter_Criteria_2__c = null;
        customRollupConfig.reduivy__Filter_Criteria_3__c = null;
        customRollupConfig.reduivy__Filter_Criteria_4__c = null;
        customRollupConfig.reduivy__Filter_Criteria_5__c = null;
        customRollupConfig.reduivy__Parent_Relationship_Field__c = 'reduivy__Transaction_Order__c';
        customRollupConfig.reduivy__Active__c = true;
        customRollupConfig.reduivy__Sequence2__c = 1;
        return customRollupConfig;
    }

    public static reduivy__Custom_Rollup_Config__mdt createCustomRollupConfigMINDECIMAL() {
        reduivy__Custom_Rollup_Config__mdt customRollupConfig = new reduivy__Custom_Rollup_Config__mdt();
        customRollupConfig.DeveloperName = 'testCustomRollupSumNumericCURRENCY';
        customRollupConfig.reduivy__Master_Object_Name__c = 'reduivy__Transaction_Order__c';
        customRollupConfig.reduivy__Master_Object_Field_Name__c = 'reduivy__Total_Amount__c';
        customRollupConfig.reduivy__Child_Object_Name__c = 'reduivy__Transaction_Line_Item__c';
        customRollupConfig.reduivy__Child_Object_Field_Name__c = 'reduivy__Total_Amount__c';
        customRollupConfig.reduivy__Rollup_Type__c = 'MIN';
        customRollupConfig.reduivy__Field_Type__c = 'DECIMAL';
        customRollupConfig.reduivy__Filter_Criteria_1__c = null;
        customRollupConfig.reduivy__Filter_Criteria_2__c = null;
        customRollupConfig.reduivy__Filter_Criteria_3__c = null;
        customRollupConfig.reduivy__Filter_Criteria_4__c = null;
        customRollupConfig.reduivy__Filter_Criteria_5__c = null;
        customRollupConfig.reduivy__Parent_Relationship_Field__c = 'reduivy__Transaction_Order__c';
        customRollupConfig.reduivy__Active__c = true;
        customRollupConfig.reduivy__Sequence2__c = 1;
        return customRollupConfig;
    }

    public static reduivy__Custom_Rollup_Config__mdt createCustomRollupConfigMAXDECIMAL() {
        reduivy__Custom_Rollup_Config__mdt customRollupConfig = new reduivy__Custom_Rollup_Config__mdt();
        customRollupConfig.DeveloperName = 'testCustomRollupSumNumericCURRENCY';
        customRollupConfig.reduivy__Master_Object_Name__c = 'reduivy__Transaction_Order__c';
        customRollupConfig.reduivy__Master_Object_Field_Name__c = 'reduivy__Total_Amount__c';
        customRollupConfig.reduivy__Child_Object_Name__c = 'reduivy__Transaction_Line_Item__c';
        customRollupConfig.reduivy__Child_Object_Field_Name__c = 'reduivy__Total_Amount__c';
        customRollupConfig.reduivy__Rollup_Type__c = 'MAX';
        customRollupConfig.reduivy__Field_Type__c = 'DECIMAL';
        customRollupConfig.reduivy__Filter_Criteria_1__c = null;
        customRollupConfig.reduivy__Filter_Criteria_2__c = null;
        customRollupConfig.reduivy__Filter_Criteria_3__c = null;
        customRollupConfig.reduivy__Filter_Criteria_4__c = null;
        customRollupConfig.reduivy__Filter_Criteria_5__c = null;
        customRollupConfig.reduivy__Parent_Relationship_Field__c = 'reduivy__Transaction_Order__c';
        customRollupConfig.reduivy__Active__c = true;
        customRollupConfig.reduivy__Sequence2__c = 1;
        return customRollupConfig;
    }
}