/**
 * @author      WDCi (Lean)
 * @date        Jul 2024
 * @group       Test
 * @description Test class for REDU_CustomRollupController
 * @changehistory
 * ISS-001993 02-07-2024 Lean - new class
 */
@IsTest
public inherited sharing class REDU_CustomRollupController_TEST {

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
    static void testCustomRollup(){
        
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

    /**
     * @description Test custom rollup with mute all
     */
    @IsTest
    static void testCustomRollupMuteAll(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            REDU_CustomRollupController.muteAllRollups();

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

            System.Assert.areEqual(null, testAccount.NumberOfEmployees);

            REDU_CustomRollupController.unmuteAllRollups();
        }
    }
    
    /**
     * @description Test custom rollup with unmute all
     */
    @IsTest
    static void testCustomRollupUnmuteAll(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            REDU_CustomRollupController.muteAllRollups();

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

            System.Assert.areEqual(null, testAccount.NumberOfEmployees);

            REDU_CustomRollupController.unmuteAllRollups();

            Contact testContact3 = new Contact(AccountId = testAccount.Id, LastName = 'Test3');
            Contact testContact4 = new Contact(AccountId = testAccount.Id, LastName = 'Test4');
            contactList.add(testContact3);
            contactList.add(testContact4);

            upsert contactList;

            //Assert rollup was successful
            testAccount = [SELECT NumberOfEmployees FROM Account WHERE Name = 'Test Account' LIMIT 1];

            System.Assert.areEqual(4, testAccount.NumberOfEmployees);
        }
    }

    /**
     * @description Test custom rollup with unmute by child object name
     */
    @IsTest
    static void testCustomRollupMutingByChildObject(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            REDU_CustomRollupController.muteRollups(new Set<String>{'Contact'});

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

            System.Assert.areEqual(null, testAccount.NumberOfEmployees);

            REDU_CustomRollupController.unmuteRollups(new Set<String>{'Contact'});

            Contact testContact3 = new Contact(AccountId = testAccount.Id, LastName = 'Test3');
            Contact testContact4 = new Contact(AccountId = testAccount.Id, LastName = 'Test4');
            contactList.add(testContact3);
            contactList.add(testContact4);

            upsert contactList;

            //Assert rollup was successful
            testAccount = [SELECT NumberOfEmployees FROM Account WHERE Name = 'Test Account' LIMIT 1];

            System.Assert.areEqual(4, testAccount.NumberOfEmployees);
        }
    }

    /**
     * @description Test custom rollup with unmute by non related child object name
     */
    @IsTest
    static void testCustomRollupMutingByNonRelevantChildObject(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            REDU_CustomRollupController.muteRollups(new Set<String>{'DummyObject'});

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

            System.Assert.areEqual(2, testAccount.NumberOfEmployees);

            REDU_CustomRollupController.unmuteRollups(new Set<String>{'DummyObject'});

            Contact testContact3 = new Contact(AccountId = testAccount.Id, LastName = 'Test3');
            Contact testContact4 = new Contact(AccountId = testAccount.Id, LastName = 'Test4');
            contactList.add(testContact3);
            contactList.add(testContact4);

            upsert contactList;

            //Assert rollup was successful
            testAccount = [SELECT NumberOfEmployees FROM Account WHERE Name = 'Test Account' LIMIT 1];

            System.Assert.areEqual(4, testAccount.NumberOfEmployees);
        }
    }

    /**
     * @description Test custom rollup with unmute by child to master object name
     */
    @IsTest
    static void testCustomRollupMutingByChildMasterObject(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            REDU_CustomRollupController.muteRollups(new Set<String>{'Contact>>Account'});

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

            System.Assert.areEqual(null, testAccount.NumberOfEmployees);

            REDU_CustomRollupController.unmuteRollups(new Set<String>{'Contact>>Account'});

            Contact testContact3 = new Contact(AccountId = testAccount.Id, LastName = 'Test3');
            Contact testContact4 = new Contact(AccountId = testAccount.Id, LastName = 'Test4');
            contactList.add(testContact3);
            contactList.add(testContact4);

            upsert contactList;

            //Assert rollup was successful
            testAccount = [SELECT NumberOfEmployees FROM Account WHERE Name = 'Test Account' LIMIT 1];

            System.Assert.areEqual(4, testAccount.NumberOfEmployees);
        }
    }

    /**
     * @description Test custom rollup with unmute by non related child to master object name
     */
    @IsTest
    static void testCustomRollupMutingByNonRelevantChildMasterObject(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            REDU_CustomRollupController.muteRollups(new Set<String>{'Child>>Master'});

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

            System.Assert.areEqual(2, testAccount.NumberOfEmployees);

            REDU_CustomRollupController.unmuteRollups(new Set<String>{'Child>>Master'});

            Contact testContact3 = new Contact(AccountId = testAccount.Id, LastName = 'Test3');
            Contact testContact4 = new Contact(AccountId = testAccount.Id, LastName = 'Test4');
            contactList.add(testContact3);
            contactList.add(testContact4);

            upsert contactList;

            //Assert rollup was successful
            testAccount = [SELECT NumberOfEmployees FROM Account WHERE Name = 'Test Account' LIMIT 1];

            System.Assert.areEqual(4, testAccount.NumberOfEmployees);
        }
    }

    /**
     * @description Test custom rollup with unmute by config name
     */
    @IsTest
    static void testCustomRollupMutingByConfig(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            REDU_CustomRollupController.muteRollups(new Set<String>{'testCustomRollupCOUNT'});

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

            System.Assert.areEqual(null, testAccount.NumberOfEmployees);

            REDU_CustomRollupController.unmuteRollups(new Set<String>{'testCustomRollupCOUNT'});

            Contact testContact3 = new Contact(AccountId = testAccount.Id, LastName = 'Test3');
            Contact testContact4 = new Contact(AccountId = testAccount.Id, LastName = 'Test4');
            contactList.add(testContact3);
            contactList.add(testContact4);

            upsert contactList;

            //Assert rollup was successful
            testAccount = [SELECT NumberOfEmployees FROM Account WHERE Name = 'Test Account' LIMIT 1];

            System.Assert.areEqual(4, testAccount.NumberOfEmployees);
        }
    }

    /**
     * @description Test custom rollup with unmute by non related config name
     */
    @IsTest
    static void testCustomRollupMutingByNonRelevantConfig(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            REDU_CustomRollupController.muteRollups(new Set<String>{'testDummyConfig'});

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

            System.Assert.areEqual(2, testAccount.NumberOfEmployees);

            REDU_CustomRollupController.unmuteRollups(new Set<String>{'testDummyConfig'});

            Contact testContact3 = new Contact(AccountId = testAccount.Id, LastName = 'Test3');
            Contact testContact4 = new Contact(AccountId = testAccount.Id, LastName = 'Test4');
            contactList.add(testContact3);
            contactList.add(testContact4);

            upsert contactList;

            //Assert rollup was successful
            testAccount = [SELECT NumberOfEmployees FROM Account WHERE Name = 'Test Account' LIMIT 1];

            System.Assert.areEqual(4, testAccount.NumberOfEmployees);
        }
    }
}