/**
 * @author      WDCi (Sueanne)
 * @date        Aug 2024
 * @group       Test
 * @description Test class for IFA_StudyFundingAmountRollup_EXE
 * @changehistory
 * ISS-001995 29-06-2024 Sueanne - new class
 */
@isTest
public inherited sharing class IFA_StudyFundingAmountRollup_TEST {
    
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
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        System.runAs(ADMIN_USER) {

            Test.startTest();

        	testFactory.initMasterData(SPL_Helper.getApiName());
            testFactory.initOfferingData(STM_Helper.getApiName());
            testFactory.initStudentData(IFA_Helper.getApiName(), true);
            
            Test.stopTest();
		}
    }

    /**
     * @description Test as admin for rollup allocated amount after insert individual funding allocation
     */
    @isTest
    static void testAllocatedAmountAfterInsertAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        //get study fundings
        Map<Id, reduivy__Study_Funding__c> sfdMap = new Map<Id, reduivy__Study_Funding__c>([
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c,
                (SELECT Id, reduivy__Amount__c, reduivy__Disbursed_Amount__c
                FROM reduivy__Individual_Funding_Allocations__r 
                WHERE reduivy__Status__c = :IFA_Helper.STATUS_ACTIVE)
            FROM reduivy__Study_Funding__c
        ]);

        //get current amount
        Map<Id, Decimal> countMap = new Map<Id, Decimal>();
        for(reduivy__Study_Funding__c sfd : sfdMap.values()){

            countMap.put(sfd.Id, 0);

            for(reduivy__Individual_Funding_Allocation__c ifa : sfd.reduivy__Individual_Funding_Allocations__r){

                Decimal amount = ifa.reduivy__Amount__c != null ? ifa.reduivy__Amount__c : 0;
                Decimal count = countMap.get(sfd.Id) + amount;
                countMap.put(sfd.Id, count);
            }
        }

        //get student contact
        List<Contact> studentContact = [SELECT Id
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        //create individual funding allocation
        List<reduivy__Individual_Funding_Allocation__c> ifaToInsert = new List<reduivy__Individual_Funding_Allocation__c>();

        for(reduivy__Study_Funding__c sfd : sfdMap.values()){
            ifaToInsert.add(REDU_TestData_UTIL.newIdvFundingAllocation('To test study funding amount rollup', studentContact[0].Id, sfd.Id, 1000, null, null, null, SFD_Helper.STATUS_ACTIVE));
        }

        System.runAs(ADMIN_USER){
            REDU_SystemMode_UTIL.doInsert(ifaToInsert);
        }

        //check rollup
        for(reduivy__Study_Funding__c sfd : [
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c
            FROM reduivy__Study_Funding__c
            WHERE Id IN :sfdMap.keySet()
        ]){
            System.Assert.areEqual(countMap.get(sfd.Id) + 1000, sfd.reduivy__Allocated_Amount__c, 'Study funding\'s allocated amount does not match as expected.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as admin for rollup disbursed amount after insert individual funding allocation
     */
    @isTest
    static void testDisbursedAmountAfterInsertAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        //get study fundings
        Map<Id, reduivy__Study_Funding__c> sfdMap = new Map<Id, reduivy__Study_Funding__c>([
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c,
                (SELECT Id, reduivy__Amount__c, reduivy__Disbursed_Amount__c
                FROM reduivy__Individual_Funding_Allocations__r 
                WHERE reduivy__Status__c = :IFA_Helper.STATUS_ACTIVE)
            FROM reduivy__Study_Funding__c
        ]);

        //get current amount
        Map<Id, Decimal> countMap = new Map<Id, Decimal>();
        for(reduivy__Study_Funding__c sfd : sfdMap.values()){

            countMap.put(sfd.Id, 0);

            for(reduivy__Individual_Funding_Allocation__c ifa : sfd.reduivy__Individual_Funding_Allocations__r){

                Decimal amount = ifa.reduivy__Disbursed_Amount__c != null ? ifa.reduivy__Disbursed_Amount__c : 0;
                Decimal count = countMap.get(sfd.Id) + amount;
                countMap.put(sfd.Id, count);
            }
        }

        //get student contact
        List<Contact> studentContact = [SELECT Id
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        //create individual funding allocation
        List<reduivy__Individual_Funding_Allocation__c> ifaToInsert = new List<reduivy__Individual_Funding_Allocation__c>();

        for(reduivy__Study_Funding__c sfd : sfdMap.values()){
            ifaToInsert.add(REDU_TestData_UTIL.newIdvFundingAllocation('To test study funding amount rollup', studentContact[0].Id, sfd.Id, null, null, null, 1000, SFD_Helper.STATUS_ACTIVE));
        }

        System.runAs(ADMIN_USER){
            REDU_SystemMode_UTIL.doInsert(ifaToInsert);
        }

        //check rollup
        for(reduivy__Study_Funding__c sfd : [
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c
            FROM reduivy__Study_Funding__c
            WHERE Id IN :sfdMap.keySet()
        ]){
            System.Assert.areEqual(countMap.get(sfd.Id) + 1000, sfd.reduivy__Disbursed_Amount__c, 'Study funding\'s discursed amount does not match as expected.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty for rollup allocated amount after insert individual funding allocation
     */
    @isTest
    static void testAllocatedAmountAfterInsertAsFaculty(){
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        //get study fundings
        Map<Id, reduivy__Study_Funding__c> sfdMap = new Map<Id, reduivy__Study_Funding__c>([
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c,
                (SELECT Id, reduivy__Amount__c, reduivy__Disbursed_Amount__c
                FROM reduivy__Individual_Funding_Allocations__r 
                WHERE reduivy__Status__c = :IFA_Helper.STATUS_ACTIVE)
            FROM reduivy__Study_Funding__c
        ]);

        //get current amount
        Map<Id, Decimal> countMap = new Map<Id, Decimal>();
        for(reduivy__Study_Funding__c sfd : sfdMap.values()){

            countMap.put(sfd.Id, 0);

            for(reduivy__Individual_Funding_Allocation__c ifa : sfd.reduivy__Individual_Funding_Allocations__r){

                Decimal amount = ifa.reduivy__Amount__c != null ? ifa.reduivy__Amount__c : 0;
                Decimal count = countMap.get(sfd.Id) + amount;
                countMap.put(sfd.Id, count);
            }
        }

        //get student contact
        List<Contact> studentContact = [SELECT Id
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        //create individual funding allocation
        List<reduivy__Individual_Funding_Allocation__c> ifaToInsert = new List<reduivy__Individual_Funding_Allocation__c>();

        for(reduivy__Study_Funding__c sfd : sfdMap.values()){
            ifaToInsert.add(REDU_TestData_UTIL.newIdvFundingAllocation('To test study funding amount rollup', studentContact[0].Id, sfd.Id, 1000, null, null, null, SFD_Helper.STATUS_ACTIVE));
        }

        System.runAs(FACULTY_USER){
            REDU_SystemMode_UTIL.doInsert(ifaToInsert);
        }

        //check rollup
        for(reduivy__Study_Funding__c sfd : [
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c
            FROM reduivy__Study_Funding__c
            WHERE Id IN :sfdMap.keySet()
        ]){
            System.Assert.areEqual(countMap.get(sfd.Id) + 1000, sfd.reduivy__Allocated_Amount__c, 'Study funding\'s allocated amount does not match as expected.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty for rollup disbursed amount after insert individual funding allocation
     */
    @isTest
    static void testDisbursedAmountAfterInsertAsFaculty(){
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        //get study fundings
        Map<Id, reduivy__Study_Funding__c> sfdMap = new Map<Id, reduivy__Study_Funding__c>([
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c,
                (SELECT Id, reduivy__Amount__c, reduivy__Disbursed_Amount__c
                FROM reduivy__Individual_Funding_Allocations__r 
                WHERE reduivy__Status__c = :IFA_Helper.STATUS_ACTIVE)
            FROM reduivy__Study_Funding__c
        ]);

        //get current amount
        Map<Id, Decimal> countMap = new Map<Id, Decimal>();
        for(reduivy__Study_Funding__c sfd : sfdMap.values()){

            countMap.put(sfd.Id, 0);

            for(reduivy__Individual_Funding_Allocation__c ifa : sfd.reduivy__Individual_Funding_Allocations__r){

                Decimal amount = ifa.reduivy__Disbursed_Amount__c != null ? ifa.reduivy__Disbursed_Amount__c : 0;
                Decimal count = countMap.get(sfd.Id) + amount;
                countMap.put(sfd.Id, count);
            }
        }

        //get student contact
        List<Contact> studentContact = [SELECT Id
            FROM Contact 
            WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT 
            AND reduivy__Sample_Record_Code__c <> ''
            LIMIT 1
        ];
        
        //create individual funding allocation
        List<reduivy__Individual_Funding_Allocation__c> ifaToInsert = new List<reduivy__Individual_Funding_Allocation__c>();

        for(reduivy__Study_Funding__c sfd : sfdMap.values()){
            ifaToInsert.add(REDU_TestData_UTIL.newIdvFundingAllocation('To test study funding amount rollup', studentContact[0].Id, sfd.Id, null, null, null, 1000, SFD_Helper.STATUS_ACTIVE));
        }

        System.runAs(FACULTY_USER){
            REDU_SystemMode_UTIL.doInsert(ifaToInsert);
        }

        //check rollup
        for(reduivy__Study_Funding__c sfd : [
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c
            FROM reduivy__Study_Funding__c
            WHERE Id IN :sfdMap.keySet()
        ]){
            System.Assert.areEqual(countMap.get(sfd.Id) + 1000, sfd.reduivy__Disbursed_Amount__c, 'Study funding\'s discursed amount does not match as expected.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as student for rollup allocated amount after insert individual funding allocation
     */
    @isTest
    static void testAllocatedAmountAfterInsertAsStudent(){
        Test.startTest();

        User studentUser = testFactory.getStudentUser();

        //get study fundings
        Map<Id, reduivy__Study_Funding__c> sfdMap = new Map<Id, reduivy__Study_Funding__c>([
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c,
                (SELECT Id, reduivy__Amount__c, reduivy__Disbursed_Amount__c
                FROM reduivy__Individual_Funding_Allocations__r 
                WHERE reduivy__Status__c = :IFA_Helper.STATUS_ACTIVE)
            FROM reduivy__Study_Funding__c
        ]);

        //get current amount
        Map<Id, Decimal> countMap = new Map<Id, Decimal>();
        for(reduivy__Study_Funding__c sfd : sfdMap.values()){

            countMap.put(sfd.Id, 0);

            for(reduivy__Individual_Funding_Allocation__c ifa : sfd.reduivy__Individual_Funding_Allocations__r){

                Decimal amount = ifa.reduivy__Amount__c != null ? ifa.reduivy__Amount__c : 0;
                Decimal count = countMap.get(sfd.Id) + amount;
                countMap.put(sfd.Id, count);
            }
        }
        
        //create individual funding allocation
        List<reduivy__Individual_Funding_Allocation__c> ifaToInsert = new List<reduivy__Individual_Funding_Allocation__c>();

        for(reduivy__Study_Funding__c sfd : sfdMap.values()){
            ifaToInsert.add(REDU_TestData_UTIL.newIdvFundingAllocation('To test study funding amount rollup', studentUser.contactId, sfd.Id, 1000, null, null, null, SFD_Helper.STATUS_ACTIVE));
        }

        System.runAs(studentUser){
            REDU_SystemMode_UTIL.doInsert(ifaToInsert);
        }

        //check rollup
        for(reduivy__Study_Funding__c sfd : [
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c
            FROM reduivy__Study_Funding__c
            WHERE Id IN :sfdMap.keySet()
        ]){
            System.Assert.areEqual(countMap.get(sfd.Id) + 1000, sfd.reduivy__Allocated_Amount__c, 'Study funding\'s allocated amount does not match as expected.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as student for rollup disbursed amount after insert individual funding allocation
     */
    @isTest
    static void testDisbursedAmountAfterInsertAsStudent(){
        Test.startTest();

        User studentUser = testFactory.getStudentUser();

        //get study fundings
        Map<Id, reduivy__Study_Funding__c> sfdMap = new Map<Id, reduivy__Study_Funding__c>([
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c,
                (SELECT Id, reduivy__Amount__c, reduivy__Disbursed_Amount__c
                FROM reduivy__Individual_Funding_Allocations__r 
                WHERE reduivy__Status__c = :IFA_Helper.STATUS_ACTIVE)
            FROM reduivy__Study_Funding__c
        ]);

        //get current amount
        Map<Id, Decimal> countMap = new Map<Id, Decimal>();
        for(reduivy__Study_Funding__c sfd : sfdMap.values()){

            countMap.put(sfd.Id, 0);

            for(reduivy__Individual_Funding_Allocation__c ifa : sfd.reduivy__Individual_Funding_Allocations__r){

                Decimal amount = ifa.reduivy__Disbursed_Amount__c != null ? ifa.reduivy__Disbursed_Amount__c : 0;
                Decimal count = countMap.get(sfd.Id) + amount;
                countMap.put(sfd.Id, count);
            }
        }
        
        //create individual funding allocation
        List<reduivy__Individual_Funding_Allocation__c> ifaToInsert = new List<reduivy__Individual_Funding_Allocation__c>();

        for(reduivy__Study_Funding__c sfd : sfdMap.values()){
            ifaToInsert.add(REDU_TestData_UTIL.newIdvFundingAllocation('To test study funding amount rollup', studentUser.contactId, sfd.Id, null, null, null, 1000, SFD_Helper.STATUS_ACTIVE));
        }

        System.runAs(studentUser){
            REDU_SystemMode_UTIL.doInsert(ifaToInsert);
        }

        //check rollup
        for(reduivy__Study_Funding__c sfd : [
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c
            FROM reduivy__Study_Funding__c
            WHERE Id IN :sfdMap.keySet()
        ]){
            System.Assert.areEqual(countMap.get(sfd.Id) + 1000, sfd.reduivy__Disbursed_Amount__c, 'Study funding\'s discursed amount does not match as expected.');
        }

        Test.stopTest();
    }



    /**
     * @description Test as admin for rollup allocated amount after update individual funding allocation
     */
    @isTest
    static void testAllocatedAmountAfterUpdateAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        //get study fundings
        Map<Id, reduivy__Study_Funding__c> sfdMap = new Map<Id, reduivy__Study_Funding__c>([
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c,
                (SELECT Id, reduivy__Amount__c, reduivy__Disbursed_Amount__c
                FROM reduivy__Individual_Funding_Allocations__r 
                WHERE reduivy__Status__c = :IFA_Helper.STATUS_ACTIVE)
            FROM reduivy__Study_Funding__c
        ]);

        List<reduivy__Individual_Funding_Allocation__c> ifaToUpdate = new List<reduivy__Individual_Funding_Allocation__c>();
        Map<Id, Decimal> countMap = new Map<Id, Decimal>();

        for(reduivy__Study_Funding__c sfd : sfdMap.values()){

            countMap.put(sfd.Id, 0);

            for(reduivy__Individual_Funding_Allocation__c ifa : sfd.reduivy__Individual_Funding_Allocations__r){

                Decimal amount = 100;
                Decimal count = countMap.get(sfd.Id) + amount;
                countMap.put(sfd.Id, count);

                reduivy__Individual_Funding_Allocation__c ifaUpdate = new reduivy__Individual_Funding_Allocation__c();
                ifaUpdate.Id = ifa.Id;
                ifaUpdate.reduivy__Amount__c = amount;
                ifaToUpdate.add(ifaUpdate);
            }
        }

        System.runAs(ADMIN_USER){
            REDU_SystemMode_UTIL.doUpdate(ifaToUpdate);
        }

        //check individual session enrollment rollup
        for(reduivy__Study_Funding__c sfd : [
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c
            FROM reduivy__Study_Funding__c
            WHERE Id IN :sfdMap.keySet()
        ]){
            Decimal amount = sfd.reduivy__Allocated_Amount__c != null ? sfd.reduivy__Allocated_Amount__c : 0;
            System.Assert.areEqual(countMap.get(sfd.Id), amount, 'Study funding\'s allocated amount does not match as expected.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as admin for rollup disbursed amount after update individual funding allocation
     */
    @isTest
    static void testDisbursedAmountAfterUpdateAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        //get study fundings
        Map<Id, reduivy__Study_Funding__c> sfdMap = new Map<Id, reduivy__Study_Funding__c>([
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c,
                (SELECT Id, reduivy__Amount__c, reduivy__Disbursed_Amount__c
                FROM reduivy__Individual_Funding_Allocations__r 
                WHERE reduivy__Status__c = :IFA_Helper.STATUS_ACTIVE)
            FROM reduivy__Study_Funding__c
        ]);

        List<reduivy__Individual_Funding_Allocation__c> ifaToUpdate = new List<reduivy__Individual_Funding_Allocation__c>();
        Map<Id, Decimal> countMap = new Map<Id, Decimal>();

        for(reduivy__Study_Funding__c sfd : sfdMap.values()){

            countMap.put(sfd.Id, 0);

            for(reduivy__Individual_Funding_Allocation__c ifa : sfd.reduivy__Individual_Funding_Allocations__r){

                Decimal amount = 100;
                Decimal count = countMap.get(sfd.Id) + amount;
                countMap.put(sfd.Id, count);

                reduivy__Individual_Funding_Allocation__c ifaUpdate = new reduivy__Individual_Funding_Allocation__c();
                ifaUpdate.Id = ifa.Id;
                ifaUpdate.reduivy__Disbursed_Amount__c = amount;
                ifaToUpdate.add(ifaUpdate);
            }
        }

        System.runAs(ADMIN_USER){
            REDU_SystemMode_UTIL.doUpdate(ifaToUpdate);
        }

        //check individual session enrollment rollup
        for(reduivy__Study_Funding__c sfd : [
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c
            FROM reduivy__Study_Funding__c
            WHERE Id IN :sfdMap.keySet()
        ]){
            Decimal amount = sfd.reduivy__Disbursed_Amount__c != null ? sfd.reduivy__Disbursed_Amount__c : 0;
            System.Assert.areEqual(countMap.get(sfd.Id), amount, 'Study funding\'s disbursed amount does not match as expected.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty for rollup allocated amount after update individual funding allocation
     */
    @isTest
    static void testAllocatedAmountAfterUpdateAsFaculty(){
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        //get study fundings
        Map<Id, reduivy__Study_Funding__c> sfdMap = new Map<Id, reduivy__Study_Funding__c>([
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c,
                (SELECT Id, reduivy__Amount__c, reduivy__Disbursed_Amount__c
                FROM reduivy__Individual_Funding_Allocations__r 
                WHERE reduivy__Status__c = :IFA_Helper.STATUS_ACTIVE)
            FROM reduivy__Study_Funding__c
        ]);

        List<reduivy__Individual_Funding_Allocation__c> ifaToUpdate = new List<reduivy__Individual_Funding_Allocation__c>();
        Map<Id, Decimal> countMap = new Map<Id, Decimal>();

        for(reduivy__Study_Funding__c sfd : sfdMap.values()){

            countMap.put(sfd.Id, 0);

            for(reduivy__Individual_Funding_Allocation__c ifa : sfd.reduivy__Individual_Funding_Allocations__r){

                Decimal amount = 100;
                Decimal count = countMap.get(sfd.Id) + amount;
                countMap.put(sfd.Id, count);

                reduivy__Individual_Funding_Allocation__c ifaUpdate = new reduivy__Individual_Funding_Allocation__c();
                ifaUpdate.Id = ifa.Id;
                ifaUpdate.reduivy__Amount__c = amount;
                ifaToUpdate.add(ifaUpdate);
            }
        }

        System.runAs(FACULTY_USER){
            REDU_SystemMode_UTIL.doUpdate(ifaToUpdate);
        }

        //check individual session enrollment rollup
        for(reduivy__Study_Funding__c sfd : [
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c
            FROM reduivy__Study_Funding__c
            WHERE Id IN :sfdMap.keySet()
        ]){
            Decimal amount = sfd.reduivy__Allocated_Amount__c != null ? sfd.reduivy__Allocated_Amount__c : 0;
            System.Assert.areEqual(countMap.get(sfd.Id), amount, 'Study funding\'s allocated amount does not match as expected.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty for rollup disbursed amount after update individual funding allocation
     */
    @isTest
    static void testDisbursedAmountAfterUpdateAsFaculty(){
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        //get study fundings
        Map<Id, reduivy__Study_Funding__c> sfdMap = new Map<Id, reduivy__Study_Funding__c>([
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c,
                (SELECT Id, reduivy__Amount__c, reduivy__Disbursed_Amount__c
                FROM reduivy__Individual_Funding_Allocations__r 
                WHERE reduivy__Status__c = :IFA_Helper.STATUS_ACTIVE)
            FROM reduivy__Study_Funding__c
        ]);

        List<reduivy__Individual_Funding_Allocation__c> ifaToUpdate = new List<reduivy__Individual_Funding_Allocation__c>();
        Map<Id, Decimal> countMap = new Map<Id, Decimal>();

        for(reduivy__Study_Funding__c sfd : sfdMap.values()){

            countMap.put(sfd.Id, 0);

            for(reduivy__Individual_Funding_Allocation__c ifa : sfd.reduivy__Individual_Funding_Allocations__r){

                Decimal amount = 100;
                Decimal count = countMap.get(sfd.Id) + amount;
                countMap.put(sfd.Id, count);

                reduivy__Individual_Funding_Allocation__c ifaUpdate = new reduivy__Individual_Funding_Allocation__c();
                ifaUpdate.Id = ifa.Id;
                ifaUpdate.reduivy__Disbursed_Amount__c = amount;
                ifaToUpdate.add(ifaUpdate);
            }
        }

        System.runAs(FACULTY_USER){
            REDU_SystemMode_UTIL.doUpdate(ifaToUpdate);
        }

        //check individual session enrollment rollup
        for(reduivy__Study_Funding__c sfd : [
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c
            FROM reduivy__Study_Funding__c
            WHERE Id IN :sfdMap.keySet()
        ]){
            Decimal amount = sfd.reduivy__Disbursed_Amount__c != null ? sfd.reduivy__Disbursed_Amount__c : 0;
            System.Assert.areEqual(countMap.get(sfd.Id), amount, 'Study funding\'s disbursed amount does not match as expected.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as student for rollup allocated amount after update individual funding allocation
     */
    @isTest
    static void testAllocatedAmountAfterUpdateAsStudent(){
        Test.startTest();

        User studentUser = testFactory.getStudentUser();

        //get study fundings
        Map<Id, reduivy__Study_Funding__c> sfdMap = new Map<Id, reduivy__Study_Funding__c>([
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c, 
                (SELECT Id, reduivy__Amount__c, reduivy__Disbursed_Amount__c, reduivy__Contact__c
                FROM reduivy__Individual_Funding_Allocations__r 
                WHERE reduivy__Status__c = :IFA_Helper.STATUS_ACTIVE)
            FROM reduivy__Study_Funding__c
        ]);

        List<reduivy__Individual_Funding_Allocation__c> ifaToUpdate = new List<reduivy__Individual_Funding_Allocation__c>();
        Map<Id, Decimal> countMap = new Map<Id, Decimal>();

        for(reduivy__Study_Funding__c sfd : sfdMap.values()){

            countMap.put(sfd.Id, 0);

            for(reduivy__Individual_Funding_Allocation__c ifa : sfd.reduivy__Individual_Funding_Allocations__r){

                Decimal amount = ifa.reduivy__Amount__c != null ? ifa.reduivy__Amount__c : 0;

                if(ifa.reduivy__Contact__c == studentUser.contactId){
                    amount = 100;

                    reduivy__Individual_Funding_Allocation__c ifaUpdate = new reduivy__Individual_Funding_Allocation__c();
                    ifaUpdate.Id = ifa.Id;
                    ifaUpdate.reduivy__Amount__c = amount;
                    ifaToUpdate.add(ifaUpdate);
                }

                Decimal count = countMap.get(sfd.Id) + amount;
                countMap.put(sfd.Id, count);
            }
        }

        System.runAs(studentUser){
            REDU_SystemMode_UTIL.doUpdate(ifaToUpdate);
        }

        //check individual session enrollment rollup
        for(reduivy__Study_Funding__c sfd : [
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c
            FROM reduivy__Study_Funding__c
            WHERE Id IN :sfdMap.keySet()
        ]){
            Decimal amount = sfd.reduivy__Allocated_Amount__c != null ? sfd.reduivy__Allocated_Amount__c : 0;
            System.Assert.areEqual(countMap.get(sfd.Id), amount, 'Study funding\'s allocated amount does not match as expected.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as student for rollup disbursed amount after update individual funding allocation
     */
    @isTest
    static void testDisbursedAmountAfterUpdateAsStudent(){
        Test.startTest();

        User studentUser = testFactory.getStudentUser();

        //get study fundings
        Map<Id, reduivy__Study_Funding__c> sfdMap = new Map<Id, reduivy__Study_Funding__c>([
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c,
                (SELECT Id, reduivy__Amount__c, reduivy__Disbursed_Amount__c, reduivy__Contact__c
                FROM reduivy__Individual_Funding_Allocations__r 
                WHERE reduivy__Status__c = :IFA_Helper.STATUS_ACTIVE)
            FROM reduivy__Study_Funding__c
        ]);

        List<reduivy__Individual_Funding_Allocation__c> ifaToUpdate = new List<reduivy__Individual_Funding_Allocation__c>();
        Map<Id, Decimal> countMap = new Map<Id, Decimal>();

        for(reduivy__Study_Funding__c sfd : sfdMap.values()){

            countMap.put(sfd.Id, 0);

            for(reduivy__Individual_Funding_Allocation__c ifa : sfd.reduivy__Individual_Funding_Allocations__r){

                Decimal amount = ifa.reduivy__Disbursed_Amount__c != null ? ifa.reduivy__Disbursed_Amount__c : 0;

                if(ifa.reduivy__Contact__c == studentUser.contactId){
                    amount = 100;
                    
                    reduivy__Individual_Funding_Allocation__c ifaUpdate = new reduivy__Individual_Funding_Allocation__c();
                    ifaUpdate.Id = ifa.Id;
                    ifaUpdate.reduivy__Disbursed_Amount__c = amount;
                    ifaToUpdate.add(ifaUpdate);
                }

                Decimal count = countMap.get(sfd.Id) + amount;
                countMap.put(sfd.Id, count);
            }
        }

        System.runAs(studentUser){
            REDU_SystemMode_UTIL.doUpdate(ifaToUpdate);
        }

        //check individual session enrollment rollup
        for(reduivy__Study_Funding__c sfd : [
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c
            FROM reduivy__Study_Funding__c
            WHERE Id IN :sfdMap.keySet()
        ]){
            Decimal amount = sfd.reduivy__Disbursed_Amount__c != null ? sfd.reduivy__Disbursed_Amount__c : 0;
            System.Assert.areEqual(countMap.get(sfd.Id), amount, 'Study funding\'s disbursed amount does not match as expected.');
        }

        Test.stopTest();
    }


    /**
     * @description Test as admin for rollup allocated amount after delete individual funding allocation
     */
    @isTest
    static void testAllocatedAmountAfterDeleteAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        //get study fundings
        Map<Id, reduivy__Study_Funding__c> sfdMap = new Map<Id, reduivy__Study_Funding__c>([
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c,
                (SELECT Id, reduivy__Amount__c, reduivy__Disbursed_Amount__c
                FROM reduivy__Individual_Funding_Allocations__r 
                WHERE reduivy__Status__c = :IFA_Helper.STATUS_ACTIVE)
            FROM reduivy__Study_Funding__c
        ]);

        List<reduivy__Individual_Funding_Allocation__c> ifaToDelete = new List<reduivy__Individual_Funding_Allocation__c>();

        for(reduivy__Study_Funding__c sfd : sfdMap.values()){

            for(reduivy__Individual_Funding_Allocation__c ifa : sfd.reduivy__Individual_Funding_Allocations__r){
                ifaToDelete.add(ifa);
            }
        }

        System.runAs(ADMIN_USER){
            REDU_SystemMode_UTIL.doDelete(ifaToDelete);
        }

        //check individual session enrollment rollup
        for(reduivy__Study_Funding__c sfd : [
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c
            FROM reduivy__Study_Funding__c
            WHERE Id IN :sfdMap.keySet()
        ]){
            Decimal amount = sfd.reduivy__Allocated_Amount__c != null ? sfd.reduivy__Allocated_Amount__c : 0;
            System.Assert.areEqual(0, amount, 'Study funding\'s allocated amount does not match as expected.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as admin for rollup disbursed amount after delete individual funding allocation
     */
    @isTest
    static void testDisbursedAmountAfterDeleteAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        //get study fundings
        Map<Id, reduivy__Study_Funding__c> sfdMap = new Map<Id, reduivy__Study_Funding__c>([
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c,
                (SELECT Id, reduivy__Amount__c, reduivy__Disbursed_Amount__c
                FROM reduivy__Individual_Funding_Allocations__r 
                WHERE reduivy__Status__c = :IFA_Helper.STATUS_ACTIVE)
            FROM reduivy__Study_Funding__c
        ]);

        List<reduivy__Individual_Funding_Allocation__c> ifaToDelete = new List<reduivy__Individual_Funding_Allocation__c>();

        for(reduivy__Study_Funding__c sfd : sfdMap.values()){

            for(reduivy__Individual_Funding_Allocation__c ifa : sfd.reduivy__Individual_Funding_Allocations__r){
                ifaToDelete.add(ifa);
            }
        }

        System.runAs(ADMIN_USER){
            REDU_SystemMode_UTIL.doDelete(ifaToDelete);
        }

        //check individual session enrollment rollup
        for(reduivy__Study_Funding__c sfd : [
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c
            FROM reduivy__Study_Funding__c
            WHERE Id IN :sfdMap.keySet()
        ]){
            Decimal amount = sfd.reduivy__Disbursed_Amount__c != null ? sfd.reduivy__Disbursed_Amount__c : 0;
            System.Assert.areEqual(0, amount, 'Study funding\'s disbursed amount does not match as expected.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty for rollup allocated amount after delete individual funding allocation
     */
    @isTest
    static void testAllocatedAmountAfterDeleteAsFaculty(){
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        //get study fundings
        Map<Id, reduivy__Study_Funding__c> sfdMap = new Map<Id, reduivy__Study_Funding__c>([
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c,
                (SELECT Id, reduivy__Amount__c, reduivy__Disbursed_Amount__c
                FROM reduivy__Individual_Funding_Allocations__r 
                WHERE reduivy__Status__c = :IFA_Helper.STATUS_ACTIVE)
            FROM reduivy__Study_Funding__c
        ]);

        List<reduivy__Individual_Funding_Allocation__c> ifaToDelete = new List<reduivy__Individual_Funding_Allocation__c>();

        for(reduivy__Study_Funding__c sfd : sfdMap.values()){

            for(reduivy__Individual_Funding_Allocation__c ifa : sfd.reduivy__Individual_Funding_Allocations__r){
                ifaToDelete.add(ifa);
            }
        }

        System.runAs(FACULTY_USER){
            REDU_SystemMode_UTIL.doDelete(ifaToDelete);
        }

        //check individual session enrollment rollup
        for(reduivy__Study_Funding__c sfd : [
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c
            FROM reduivy__Study_Funding__c
            WHERE Id IN :sfdMap.keySet()
        ]){
            Decimal amount = sfd.reduivy__Allocated_Amount__c != null ? sfd.reduivy__Allocated_Amount__c : 0;
            System.Assert.areEqual(0, amount, 'Study funding\'s allocated amount does not match as expected.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty for rollup disbursed amount after delete individual funding allocation
     */
    @isTest
    static void testDisbursedAmountAfterDeleteAsFaculty(){
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        //get study fundings
        Map<Id, reduivy__Study_Funding__c> sfdMap = new Map<Id, reduivy__Study_Funding__c>([
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c,
                (SELECT Id, reduivy__Amount__c, reduivy__Disbursed_Amount__c
                FROM reduivy__Individual_Funding_Allocations__r 
                WHERE reduivy__Status__c = :IFA_Helper.STATUS_ACTIVE)
            FROM reduivy__Study_Funding__c
        ]);

        List<reduivy__Individual_Funding_Allocation__c> ifaToDelete = new List<reduivy__Individual_Funding_Allocation__c>();

        for(reduivy__Study_Funding__c sfd : sfdMap.values()){

            for(reduivy__Individual_Funding_Allocation__c ifa : sfd.reduivy__Individual_Funding_Allocations__r){
                ifaToDelete.add(ifa);
            }
        }

        System.runAs(FACULTY_USER){
            REDU_SystemMode_UTIL.doDelete(ifaToDelete);
        }

        //check individual session enrollment rollup
        for(reduivy__Study_Funding__c sfd : [
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c
            FROM reduivy__Study_Funding__c
            WHERE Id IN :sfdMap.keySet()
        ]){
            Decimal amount = sfd.reduivy__Disbursed_Amount__c != null ? sfd.reduivy__Disbursed_Amount__c : 0;
            System.Assert.areEqual(0, amount, 'Study funding\'s disbursed amount does not match as expected.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as student for rollup allocated amount after delete individual funding allocation
     */
    @isTest
    static void testAllocatedAmountAfterDeleteAsStudent(){
        Test.startTest();

        User studentUser = testFactory.getStudentUser();

        //get study fundings
        Map<Id, reduivy__Study_Funding__c> sfdMap = new Map<Id, reduivy__Study_Funding__c>([
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c,
                (SELECT Id, reduivy__Amount__c, reduivy__Disbursed_Amount__c, reduivy__Contact__c
                FROM reduivy__Individual_Funding_Allocations__r 
                WHERE reduivy__Status__c = :IFA_Helper.STATUS_ACTIVE)
            FROM reduivy__Study_Funding__c
        ]);

        List<reduivy__Individual_Funding_Allocation__c> ifaToDelete = new List<reduivy__Individual_Funding_Allocation__c>();
        Map<Id, Decimal> countMap = new Map<Id, Decimal>();

        for(reduivy__Study_Funding__c sfd : sfdMap.values()){

            countMap.put(sfd.Id, 0);

            for(reduivy__Individual_Funding_Allocation__c ifa : sfd.reduivy__Individual_Funding_Allocations__r){

                Decimal amount = ifa.reduivy__Amount__c != null ? ifa.reduivy__Amount__c : 0;
                
                if(ifa.reduivy__Contact__c == studentUser.contactId){
                    ifaToDelete.add(ifa);
                    amount = 0;
                }

                Decimal count = countMap.get(sfd.Id) + amount;
                countMap.put(sfd.Id, count);
            }
        }

        System.runAs(studentUser){
            REDU_SystemMode_UTIL.doDelete(ifaToDelete);
        }

        //check individual session enrollment rollup
        for(reduivy__Study_Funding__c sfd : [
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c
            FROM reduivy__Study_Funding__c
            WHERE Id IN :sfdMap.keySet()
        ]){
            Decimal amount = sfd.reduivy__Allocated_Amount__c != null ? sfd.reduivy__Allocated_Amount__c : 0;
            System.Assert.areEqual(countMap.get(sfd.Id), amount, 'Study funding\'s allocated amount does not match as expected.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as student for rollup disbursed amount after delete individual funding allocation
     */
    @isTest
    static void testDisbursedAmountAfterDeleteAsStudent(){
        Test.startTest();

        User studentUser = testFactory.getStudentUser();

        //get study fundings
        Map<Id, reduivy__Study_Funding__c> sfdMap = new Map<Id, reduivy__Study_Funding__c>([
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c,
                (SELECT Id, reduivy__Amount__c, reduivy__Disbursed_Amount__c, reduivy__Contact__c
                FROM reduivy__Individual_Funding_Allocations__r 
                WHERE reduivy__Status__c = :IFA_Helper.STATUS_ACTIVE)
            FROM reduivy__Study_Funding__c
        ]);

        List<reduivy__Individual_Funding_Allocation__c> ifaToDelete = new List<reduivy__Individual_Funding_Allocation__c>();
        Map<Id, Decimal> countMap = new Map<Id, Decimal>();

        for(reduivy__Study_Funding__c sfd : sfdMap.values()){

            countMap.put(sfd.Id, 0);

            for(reduivy__Individual_Funding_Allocation__c ifa : sfd.reduivy__Individual_Funding_Allocations__r){
                
                Decimal amount = ifa.reduivy__Disbursed_Amount__c != null ? ifa.reduivy__Disbursed_Amount__c : 0;
                
                if(ifa.reduivy__Contact__c == studentUser.contactId){
                    ifaToDelete.add(ifa);
                    amount = 0;
                }

                Decimal count = countMap.get(sfd.Id) + amount;
                countMap.put(sfd.Id, count);
            }
        }

        System.runAs(studentUser){
            REDU_SystemMode_UTIL.doDelete(ifaToDelete);
        }

        //check individual session enrollment rollup
        for(reduivy__Study_Funding__c sfd : [
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c
            FROM reduivy__Study_Funding__c
            WHERE Id IN :sfdMap.keySet()
        ]){
            Decimal amount = sfd.reduivy__Disbursed_Amount__c != null ? sfd.reduivy__Disbursed_Amount__c : 0;
            System.Assert.areEqual(countMap.get(sfd.Id), amount, 'Study funding\'s disbursed amount does not match as expected.');
        }

        Test.stopTest();
    }



    /**
     * @description Test as admin for rollup allocated amount after undelete individual funding allocation
     */
    @isTest
    static void testAllocatedAmountAfterUndeleteAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        //get study fundings
        Map<Id, reduivy__Study_Funding__c> sfdMap = new Map<Id, reduivy__Study_Funding__c>([
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c,
                (SELECT Id, reduivy__Amount__c, reduivy__Disbursed_Amount__c
                FROM reduivy__Individual_Funding_Allocations__r 
                WHERE reduivy__Status__c = :IFA_Helper.STATUS_ACTIVE)
            FROM reduivy__Study_Funding__c
        ]);

        List<reduivy__Individual_Funding_Allocation__c> ifaToDelete = new List<reduivy__Individual_Funding_Allocation__c>();
        Map<Id, Decimal> countMap = new Map<Id, Decimal>();

        for(reduivy__Study_Funding__c sfd : sfdMap.values()){

            countMap.put(sfd.Id, 0);

            for(reduivy__Individual_Funding_Allocation__c ifa : sfd.reduivy__Individual_Funding_Allocations__r){

                Decimal amount = ifa.reduivy__Amount__c != null ? ifa.reduivy__Amount__c : 0;
                Decimal count = countMap.get(sfd.Id) + amount;
                countMap.put(sfd.Id, count);

                ifaToDelete.add(ifa);
            }
        }

        System.runAs(ADMIN_USER){
            REDU_SystemMode_UTIL.doDelete(ifaToDelete);

            undelete ifaToDelete;
        }

        //check individual session enrollment rollup
        for(reduivy__Study_Funding__c sfd : [
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c
            FROM reduivy__Study_Funding__c
            WHERE Id IN :sfdMap.keySet()
        ]){
            Decimal amount = sfd.reduivy__Allocated_Amount__c != null ? sfd.reduivy__Allocated_Amount__c : 0;
            System.Assert.areEqual(countMap.get(sfd.Id), amount, 'Study funding\'s allocated amount does not match as expected.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as admin for rollup disbursed amount after undelete individual funding allocation
     */
    @isTest
    static void testDisbursedAmountAfterUndeleteAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        //get study fundings
        Map<Id, reduivy__Study_Funding__c> sfdMap = new Map<Id, reduivy__Study_Funding__c>([
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c,
                (SELECT Id, reduivy__Amount__c, reduivy__Disbursed_Amount__c
                FROM reduivy__Individual_Funding_Allocations__r 
                WHERE reduivy__Status__c = :IFA_Helper.STATUS_ACTIVE)
            FROM reduivy__Study_Funding__c
        ]);

        List<reduivy__Individual_Funding_Allocation__c> ifaToDelete = new List<reduivy__Individual_Funding_Allocation__c>();
        Map<Id, Decimal> countMap = new Map<Id, Decimal>();

        for(reduivy__Study_Funding__c sfd : sfdMap.values()){

            countMap.put(sfd.Id, 0);

            for(reduivy__Individual_Funding_Allocation__c ifa : sfd.reduivy__Individual_Funding_Allocations__r){

                Decimal amount = ifa.reduivy__Disbursed_Amount__c != null ? ifa.reduivy__Disbursed_Amount__c : 0;
                Decimal count = countMap.get(sfd.Id) + amount;
                countMap.put(sfd.Id, count);

                ifaToDelete.add(ifa);
            }
        }

        System.runAs(ADMIN_USER){
            REDU_SystemMode_UTIL.doDelete(ifaToDelete);

            undelete ifaToDelete;
        }

        //check individual session enrollment rollup
        for(reduivy__Study_Funding__c sfd : [
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c
            FROM reduivy__Study_Funding__c
            WHERE Id IN :sfdMap.keySet()
        ]){
            Decimal amount = sfd.reduivy__Disbursed_Amount__c != null ? sfd.reduivy__Disbursed_Amount__c : 0;
            System.Assert.areEqual(countMap.get(sfd.Id), amount, 'Study funding\'s disbursed amount does not match as expected.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty for rollup allocated amount after undelete individual funding allocation
     */
    @isTest
    static void testAllocatedAmountAfterUndeleteAsFaculty(){
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        //get study fundings
        Map<Id, reduivy__Study_Funding__c> sfdMap = new Map<Id, reduivy__Study_Funding__c>([
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c,
                (SELECT Id, reduivy__Amount__c, reduivy__Disbursed_Amount__c
                FROM reduivy__Individual_Funding_Allocations__r 
                WHERE reduivy__Status__c = :IFA_Helper.STATUS_ACTIVE)
            FROM reduivy__Study_Funding__c
        ]);

        List<reduivy__Individual_Funding_Allocation__c> ifaToDelete = new List<reduivy__Individual_Funding_Allocation__c>();
        Map<Id, Decimal> countMap = new Map<Id, Decimal>();

        for(reduivy__Study_Funding__c sfd : sfdMap.values()){

            countMap.put(sfd.Id, 0);

            for(reduivy__Individual_Funding_Allocation__c ifa : sfd.reduivy__Individual_Funding_Allocations__r){

                Decimal amount = ifa.reduivy__Amount__c != null ? ifa.reduivy__Amount__c : 0;
                Decimal count = countMap.get(sfd.Id) + amount;
                countMap.put(sfd.Id, count);

                ifaToDelete.add(ifa);
            }
        }

        System.runAs(FACULTY_USER){
            REDU_SystemMode_UTIL.doDelete(ifaToDelete);

            undelete ifaToDelete;
        }

        //check individual session enrollment rollup
        for(reduivy__Study_Funding__c sfd : [
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c
            FROM reduivy__Study_Funding__c
            WHERE Id IN :sfdMap.keySet()
        ]){
            Decimal amount = sfd.reduivy__Allocated_Amount__c != null ? sfd.reduivy__Allocated_Amount__c : 0;
            System.Assert.areEqual(countMap.get(sfd.Id), amount, 'Study funding\'s allocated amount does not match as expected.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty for rollup disbursed amount after undelete individual funding allocation
     */
    @isTest
    static void testDisbursedAmountAfterUndeleteAsFaculty(){
                
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        Test.startTest();

        //get study fundings
        Map<Id, reduivy__Study_Funding__c> sfdMap = new Map<Id, reduivy__Study_Funding__c>([
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c,
                (SELECT Id, reduivy__Amount__c, reduivy__Disbursed_Amount__c
                FROM reduivy__Individual_Funding_Allocations__r 
                WHERE reduivy__Status__c = :IFA_Helper.STATUS_ACTIVE)
            FROM reduivy__Study_Funding__c
        ]);

        List<reduivy__Individual_Funding_Allocation__c> ifaToDelete = new List<reduivy__Individual_Funding_Allocation__c>();
        Map<Id, Decimal> countMap = new Map<Id, Decimal>();

        for(reduivy__Study_Funding__c sfd : sfdMap.values()){

            countMap.put(sfd.Id, 0);

            for(reduivy__Individual_Funding_Allocation__c ifa : sfd.reduivy__Individual_Funding_Allocations__r){

                Decimal amount = ifa.reduivy__Disbursed_Amount__c != null ? ifa.reduivy__Disbursed_Amount__c : 0;
                Decimal count = countMap.get(sfd.Id) + amount;
                countMap.put(sfd.Id, count);

                ifaToDelete.add(ifa);
            }
        }

        System.runAs(FACULTY_USER){
            REDU_SystemMode_UTIL.doDelete(ifaToDelete);

            undelete ifaToDelete;
        }

        //check individual session enrollment rollup
        for(reduivy__Study_Funding__c sfd : [
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c
            FROM reduivy__Study_Funding__c
            WHERE Id IN :sfdMap.keySet()
        ]){
            Decimal amount = sfd.reduivy__Disbursed_Amount__c != null ? sfd.reduivy__Disbursed_Amount__c : 0;
            System.Assert.areEqual(countMap.get(sfd.Id), amount, 'Study funding\'s disbursed amount does not match as expected.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as student for rollup allocated amount after undelete individual funding allocation
     */
    @isTest
    static void testAllocatedAmountAfterUndeleteAsStudent(){
        Test.startTest();

        User studentUser = testFactory.getStudentUser();

        //get study fundings
        Map<Id, reduivy__Study_Funding__c> sfdMap = new Map<Id, reduivy__Study_Funding__c>([
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c,
                (SELECT Id, reduivy__Amount__c, reduivy__Disbursed_Amount__c, reduivy__Contact__c
                FROM reduivy__Individual_Funding_Allocations__r 
                WHERE reduivy__Status__c = :IFA_Helper.STATUS_ACTIVE)
            FROM reduivy__Study_Funding__c
        ]);

        List<reduivy__Individual_Funding_Allocation__c> ifaToDelete = new List<reduivy__Individual_Funding_Allocation__c>();
        Map<Id, Decimal> countMap = new Map<Id, Decimal>();

        for(reduivy__Study_Funding__c sfd : sfdMap.values()){

            countMap.put(sfd.Id, 0);

            for(reduivy__Individual_Funding_Allocation__c ifa : sfd.reduivy__Individual_Funding_Allocations__r){

                Decimal amount = ifa.reduivy__Amount__c != null ? ifa.reduivy__Amount__c : 0;
                Decimal count = countMap.get(sfd.Id) + amount;
                countMap.put(sfd.Id, count);

                if(ifa.reduivy__Contact__c == studentUser.contactId){
                    ifaToDelete.add(ifa);
                }
            }
        }

        System.runAs(studentUser){
            REDU_SystemMode_UTIL.doDelete(ifaToDelete);

            undelete ifaToDelete;
        }

        //check individual session enrollment rollup
        for(reduivy__Study_Funding__c sfd : [
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c
            FROM reduivy__Study_Funding__c
            WHERE Id IN :sfdMap.keySet()
        ]){
            Decimal amount = sfd.reduivy__Allocated_Amount__c != null ? sfd.reduivy__Allocated_Amount__c : 0;
            System.Assert.areEqual(countMap.get(sfd.Id), amount, 'Study funding\'s allocated amount does not match as expected.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as student for rollup disbursed amount after undelete individual funding allocation
     */
    @isTest
    static void testDisbursedAmountAfterUndeleteAsStudent(){
        Test.startTest();

        User studentUser = testFactory.getStudentUser();

        //get study fundings
        Map<Id, reduivy__Study_Funding__c> sfdMap = new Map<Id, reduivy__Study_Funding__c>([
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c,
                (SELECT Id, reduivy__Amount__c, reduivy__Disbursed_Amount__c, reduivy__Contact__c
                FROM reduivy__Individual_Funding_Allocations__r 
                WHERE reduivy__Status__c = :IFA_Helper.STATUS_ACTIVE)
            FROM reduivy__Study_Funding__c
        ]);

        List<reduivy__Individual_Funding_Allocation__c> ifaToDelete = new List<reduivy__Individual_Funding_Allocation__c>();
        Map<Id, Decimal> countMap = new Map<Id, Decimal>();

        for(reduivy__Study_Funding__c sfd : sfdMap.values()){

            countMap.put(sfd.Id, 0);

            for(reduivy__Individual_Funding_Allocation__c ifa : sfd.reduivy__Individual_Funding_Allocations__r){

                Decimal amount = ifa.reduivy__Disbursed_Amount__c != null ? ifa.reduivy__Disbursed_Amount__c : 0;
                Decimal count = countMap.get(sfd.Id) + amount;
                countMap.put(sfd.Id, count);
                
                if(ifa.reduivy__Contact__c == studentUser.contactId){
                    ifaToDelete.add(ifa);
                }
            }
        }

        System.runAs(studentUser){
            REDU_SystemMode_UTIL.doDelete(ifaToDelete);

            undelete ifaToDelete;
        }

        //check individual session enrollment rollup
        for(reduivy__Study_Funding__c sfd : [
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c
            FROM reduivy__Study_Funding__c
            WHERE Id IN :sfdMap.keySet()
        ]){
            Decimal amount = sfd.reduivy__Disbursed_Amount__c != null ? sfd.reduivy__Disbursed_Amount__c : 0;
            System.Assert.areEqual(countMap.get(sfd.Id), amount, 'Study funding\'s disbursed amount does not match as expected.');
        }

        Test.stopTest();
    }



    /**
     * @description Test as admin for rollup after update study funding lookup in individual funding allcation
     */
    @isTest
    static void testUpdateAssociatedStudyFundingAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        //get study fundings
        Map<Id, reduivy__Study_Funding__c> sfdMap = new Map<Id, reduivy__Study_Funding__c>([
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c,
                (SELECT Id, reduivy__Amount__c, reduivy__Disbursed_Amount__c
                FROM reduivy__Individual_Funding_Allocations__r 
                WHERE reduivy__Status__c = :IFA_Helper.STATUS_ACTIVE)
            FROM reduivy__Study_Funding__c
        ]);

        List<reduivy__Individual_Funding_Allocation__c> ifaToUpdate = new List<reduivy__Individual_Funding_Allocation__c>();
        Map<Id, Decimal> disbursedCount = new Map<Id, Decimal>();
        Map<Id, Decimal> allocatedCount = new Map<Id, Decimal>();

        List<reduivy__Study_Funding__c> sfdList = new List<reduivy__Study_Funding__c>(sfdMap.values());
        for(reduivy__Study_Funding__c sfd : sfdMap.values()){

            //initialize count to 0
            if(!allocatedCount.containsKey(sfd.Id)){
                allocatedCount.put(sfd.Id, 0);
            }

            if(!disbursedCount.containsKey(sfd.Id)){
                disbursedCount.put(sfd.Id, 0);
            }

            for(reduivy__Individual_Funding_Allocation__c ifa : sfd.reduivy__Individual_Funding_Allocations__r){

                Id sfdId = sfd.Id;

                //update for all the IFA that associated to the first SFD's only
                //if we update all IFA from all SFD, all of SFD will do the rollup. We cannot check whether the oldIfa's SFD is rollup or not in that case.
                if(sfd.Id == sfdList[0].Id){

                    sfdId = sfdList[1].Id;

                    reduivy__Individual_Funding_Allocation__c ifaUpdate = new reduivy__Individual_Funding_Allocation__c();
                    ifaUpdate.Id = ifa.Id;
                    ifaUpdate.reduivy__Study_Funding__c = sfdId;
                    ifaToUpdate.add(ifaUpdate);

                    allocatedCount.put(sfdId, 0);
                    disbursedCount.put(sfdId, 0);
                }

                //count for updated sfd and other sfd rollup to ensure other sfd didn't do the rollup too
                Decimal allocated = ifa.reduivy__Amount__c != null ? ifa.reduivy__Amount__c : 0;
                allocatedCount.put(sfdId, allocatedCount.get(sfdId) + allocated);

                Decimal disbursed = ifa.reduivy__Disbursed_Amount__c != null ? ifa.reduivy__Disbursed_Amount__c : 0;
                disbursedCount.put(sfdId, disbursedCount.get(sfdId) + disbursed);
            }
        }

        System.runAs(ADMIN_USER){
            REDU_SystemMode_UTIL.doUpdate(ifaToUpdate);
        }

        //check individual session enrollment rollup
        for(reduivy__Study_Funding__c sfd : [
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c
            FROM reduivy__Study_Funding__c
            WHERE Id IN :sfdMap.keySet()
        ]){
            Decimal allocated = sfd.reduivy__Allocated_Amount__c != null ? sfd.reduivy__Allocated_Amount__c : 0;
            Decimal disbursed = sfd.reduivy__Disbursed_Amount__c != null ? sfd.reduivy__Disbursed_Amount__c : 0;

            System.Assert.areEqual(allocatedCount.get(sfd.Id), allocated, 'Study funding\'s allocated amount does not match as expected.');
            System.Assert.areEqual(disbursedCount.get(sfd.Id), disbursed, 'Study funding\'s disbursed amount does not match as expected.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as admin for rollup after set study funding lookup to null in individual funding allcation
     */
    @isTest
    static void testUnlinkAssociatedStudyFundingAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        //get study fundings
        Map<Id, reduivy__Study_Funding__c> sfdMap = new Map<Id, reduivy__Study_Funding__c>([
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c,
                (SELECT Id, reduivy__Amount__c, reduivy__Disbursed_Amount__c
                FROM reduivy__Individual_Funding_Allocations__r 
                WHERE reduivy__Status__c = :IFA_Helper.STATUS_ACTIVE)
            FROM reduivy__Study_Funding__c
        ]);

        List<reduivy__Individual_Funding_Allocation__c> ifaToUpdate = new List<reduivy__Individual_Funding_Allocation__c>();
        Map<Id, Decimal> disbursedCount = new Map<Id, Decimal>();
        Map<Id, Decimal> allocatedCount = new Map<Id, Decimal>();

        List<reduivy__Study_Funding__c> sfdList = new List<reduivy__Study_Funding__c>(sfdMap.values());
        for(reduivy__Study_Funding__c sfd : sfdMap.values()){

            //initialize count to 0
            if(!allocatedCount.containsKey(sfd.Id)){
                allocatedCount.put(sfd.Id, 0);
            }

            if(!disbursedCount.containsKey(sfd.Id)){
                disbursedCount.put(sfd.Id, 0);
            }

            for(reduivy__Individual_Funding_Allocation__c ifa : sfd.reduivy__Individual_Funding_Allocations__r){

                Id sfdId = sfd.Id;

                //update for all the IFA that associated to the first SFD's only
                //if we update all IFA from all SFD, all of SFD will do the rollup. We cannot check whether the oldIfa's SFD is rollup or not in that case.
                if(sfd.Id == sfdList[0].Id){

                    sfdId = sfdList[1].Id;

                    reduivy__Individual_Funding_Allocation__c ifaUpdate = new reduivy__Individual_Funding_Allocation__c();
                    ifaUpdate.Id = ifa.Id;
                    ifaUpdate.reduivy__Study_Funding__c = null;
                    ifaToUpdate.add(ifaUpdate);

                } else {

                    //count for updated sfd and other sfd rollup to ensure other sfd didn't do the rollup too
                    Decimal allocated = ifa.reduivy__Amount__c != null ? ifa.reduivy__Amount__c : 0;
                    allocatedCount.put(sfdId, allocatedCount.get(sfdId) + allocated);
    
                    Decimal disbursed = ifa.reduivy__Disbursed_Amount__c != null ? ifa.reduivy__Disbursed_Amount__c : 0;
                    disbursedCount.put(sfdId, disbursedCount.get(sfdId) + disbursed);
                }

            }
        }

        System.runAs(ADMIN_USER){
            REDU_SystemMode_UTIL.doUpdate(ifaToUpdate);
        }

        //check individual session enrollment rollup
        for(reduivy__Study_Funding__c sfd : [
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c
            FROM reduivy__Study_Funding__c
            WHERE Id IN :sfdMap.keySet()
        ]){
            Decimal allocated = sfd.reduivy__Allocated_Amount__c != null ? sfd.reduivy__Allocated_Amount__c : 0;
            Decimal disbursed = sfd.reduivy__Disbursed_Amount__c != null ? sfd.reduivy__Disbursed_Amount__c : 0;

            System.Assert.areEqual(allocatedCount.get(sfd.Id), allocated, 'Study funding\'s allocated amount does not match as expected.');
            System.Assert.areEqual(disbursedCount.get(sfd.Id), disbursed, 'Study funding\'s disbursed amount does not match as expected.');
        }

        Test.stopTest();
    }

    /**
     * @description Test as admin for update the individual funding allocation status to inactive
     */
    @isTest
    static void testUpdateIfaStatusToInactiveAsAdmin(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();

        //get study fundings
        Map<Id, reduivy__Study_Funding__c> sfdMap = new Map<Id, reduivy__Study_Funding__c>([
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c,
                (SELECT Id, reduivy__Amount__c, reduivy__Disbursed_Amount__c
                FROM reduivy__Individual_Funding_Allocations__r 
                WHERE reduivy__Status__c = :IFA_Helper.STATUS_ACTIVE)
            FROM reduivy__Study_Funding__c
        ]);

        List<reduivy__Individual_Funding_Allocation__c> ifaToUpdate = new List<reduivy__Individual_Funding_Allocation__c>();
        Map<Id, Decimal> disbursedCount = new Map<Id, Decimal>();
        Map<Id, Decimal> allocatedCount = new Map<Id, Decimal>();

        List<reduivy__Study_Funding__c> sfdList = new List<reduivy__Study_Funding__c>(sfdMap.values());
        for(reduivy__Study_Funding__c sfd : sfdMap.values()){

            //initialize count to 0
            if(!allocatedCount.containsKey(sfd.Id)){
                allocatedCount.put(sfd.Id, 0);
            }

            if(!disbursedCount.containsKey(sfd.Id)){
                disbursedCount.put(sfd.Id, 0);
            }

            for(reduivy__Individual_Funding_Allocation__c ifa : sfd.reduivy__Individual_Funding_Allocations__r){

                Id sfdId = sfd.Id;

                //update for all the IFA that associated to the first SFD's only
                //if we update all IFA from all SFD, all of SFD will do the rollup. We cannot check whether the oldIfa's SFD is rollup or not in that case.
                if(sfd.Id == sfdList[0].Id){

                    sfdId = sfdList[1].Id;

                    reduivy__Individual_Funding_Allocation__c ifaUpdate = new reduivy__Individual_Funding_Allocation__c();
                    ifaUpdate.Id = ifa.Id;
                    ifaUpdate.reduivy__Status__c = IFA_Helper.STATUS_INACTIVE;
                    ifaToUpdate.add(ifaUpdate);

                } else {

                    //count for updated sfd and other sfd rollup to ensure other sfd didn't do the rollup too
                    Decimal allocated = ifa.reduivy__Amount__c != null ? ifa.reduivy__Amount__c : 0;
                    allocatedCount.put(sfdId, allocatedCount.get(sfdId) + allocated);
    
                    Decimal disbursed = ifa.reduivy__Disbursed_Amount__c != null ? ifa.reduivy__Disbursed_Amount__c : 0;
                    disbursedCount.put(sfdId, disbursedCount.get(sfdId) + disbursed);
                }

            }
        }

        System.runAs(ADMIN_USER){
            REDU_SystemMode_UTIL.doUpdate(ifaToUpdate);
        }

        //check individual session enrollment rollup
        for(reduivy__Study_Funding__c sfd : [
            SELECT Id, reduivy__Allocated_Amount__c, reduivy__Disbursed_Amount__c
            FROM reduivy__Study_Funding__c
            WHERE Id IN :sfdMap.keySet()
        ]){
            Decimal allocated = sfd.reduivy__Allocated_Amount__c != null ? sfd.reduivy__Allocated_Amount__c : 0;
            Decimal disbursed = sfd.reduivy__Disbursed_Amount__c != null ? sfd.reduivy__Disbursed_Amount__c : 0;

            System.Assert.areEqual(allocatedCount.get(sfd.Id), allocated, 'Study funding\'s allocated amount does not match as expected.');
            System.Assert.areEqual(disbursedCount.get(sfd.Id), disbursed, 'Study funding\'s disbursed amount does not match as expected.');
        }

        Test.stopTest();
    }
} 