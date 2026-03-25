/**
 * @author      WDCi (Sueanne)
 * @date        Sept 2024
 * @group       Test
 * @description Test class for REDU_IpePathwayStudySessions_LCTRL
 * @changehistory
 * ISS-002050 26-09-2024 Sueanne - new class
 */
@IsTest
public inherited sharing class REDU_IpePathwayStudySessions_TEST {
    
    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    /**
     * @description Default method to setup required data for automated test
     */
	@TestSetup
    static void makeData(){
        
		// Create settings
		testFactory.setupDefaultSettings();
        User ADMIN_USER = testFactory.getReduAdminUser();
		
		// Create test data
        System.runAs(ADMIN_USER) {
            Test.startTest();

            testFactory.initMasterData(null);
            testFactory.initOfferingData(null);
            testFactory.initStudentData(null, true);

            Test.stopTest();
        }
        
    }

    /**
     * @description Test as admin for REDU_IpePathwayStudySessions_LCTRL.getStudySessions()
     */
    @IsTest
    static void testGetStudySessionAsAdmin(){

        Test.startTest();
        User ADMIN_USER = testFactory.getReduAdminUser();

        //get study offerings
        Map<Id, reduivy__Study_Offering__c> sofList = new Map<Id, reduivy__Study_Offering__c>([
            SELECT Id
            FROM reduivy__Study_Offering__c
        ]);

        Map<Id, Integer> sseCount = new Map<Id, Integer>();
        for(reduivy__Study_Session__c sse : [
            SELECT Id, reduivy__Study_Offering__c
            FROM reduivy__Study_Session__c
            WHERE reduivy__Study_Offering__c IN :sofList.keySet()
        ]){
            if(sseCount.containsKey(sse.reduivy__Study_Offering__c)){
                sseCount.put(sse.reduivy__Study_Offering__c, sseCount.get(sse.reduivy__Study_Offering__c) + 1);
            } else {
                sseCount.put(sse.reduivy__Study_Offering__c, 1);
            }
        }

        System.runAs(ADMIN_USER){
            
            for(reduivy__Study_Offering__c sof : sofList.values()){

                REDU_LightningResponse response = REDU_IpePathwayStudySessions_LCTRL.getStudySessions(sof.Id);
                List<reduivy__Study_Session__c> data = (List<reduivy__Study_Session__c>) JSON.deserialize(response.responseData, List<reduivy__Study_Session__c>.class);
                
                Integer count = sseCount.containsKey(sof.Id) ? sseCount.get(sof.Id) : 0;
                System.Assert.areEqual(count, data.size(), 'The response study session list length should be same.');
            }
            
        }

        Test.stopTest();
    }

    /**
     * @description Test as faculty for REDU_IpePathwayStudySessions_LCTRL.getStudySessions()
     */
    @IsTest
    static void testGetStudySessionAsFaculty(){

        Test.startTest();
        User FACULTY_USER = testFactory.getReduFacultyUser();

        //get study offerings
        Map<Id, reduivy__Study_Offering__c> sofList = new Map<Id, reduivy__Study_Offering__c>([
            SELECT Id
            FROM reduivy__Study_Offering__c
        ]);

        Map<Id, Integer> sseCount = new Map<Id, Integer>();
        for(reduivy__Study_Session__c sse : [
            SELECT Id, reduivy__Study_Offering__c
            FROM reduivy__Study_Session__c
            WHERE reduivy__Study_Offering__c IN :sofList.keySet()
        ]){
            if(sseCount.containsKey(sse.reduivy__Study_Offering__c)){
                sseCount.put(sse.reduivy__Study_Offering__c, sseCount.get(sse.reduivy__Study_Offering__c) + 1);
            } else {
                sseCount.put(sse.reduivy__Study_Offering__c, 1);
            }
        }

        System.runAs(FACULTY_USER){
            
            for(reduivy__Study_Offering__c sof : sofList.values()){

                REDU_LightningResponse response = REDU_IpePathwayStudySessions_LCTRL.getStudySessions(sof.Id);
                List<reduivy__Study_Session__c> data = (List<reduivy__Study_Session__c>) JSON.deserialize(response.responseData, List<reduivy__Study_Session__c>.class);
                
                Integer count = sseCount.containsKey(sof.Id) ? sseCount.get(sof.Id) : 0;
                System.Assert.areEqual(count, data.size(), 'The response study session list length should be same.');
            }
            
        }

        Test.stopTest();
    }

    /**
     * @description Test as student for REDU_IpePathwayStudySessions_LCTRL.getStudySessions()
     */
    @IsTest
    static void testGetStudySessionAsStudent(){

        Test.startTest();
        User studentUser = testFactory.getStudentUser();

        //get study offerings
        Map<Id, reduivy__Study_Offering__c> sofList = new Map<Id, reduivy__Study_Offering__c>([
            SELECT Id
            FROM reduivy__Study_Offering__c
        ]);

        Map<Id, Integer> sseCount = new Map<Id, Integer>();
        for(reduivy__Study_Session__c sse : [
            SELECT Id, reduivy__Study_Offering__c
            FROM reduivy__Study_Session__c
            WHERE reduivy__Study_Offering__c IN :sofList.keySet()
        ]){
            if(sseCount.containsKey(sse.reduivy__Study_Offering__c)){
                sseCount.put(sse.reduivy__Study_Offering__c, sseCount.get(sse.reduivy__Study_Offering__c) + 1);
            } else {
                sseCount.put(sse.reduivy__Study_Offering__c, 1);
            }
        }

        System.runAs(studentUser){
            
            for(reduivy__Study_Offering__c sof : sofList.values()){

                REDU_LightningResponse response = REDU_IpePathwayStudySessions_LCTRL.getStudySessions(sof.Id);
                List<reduivy__Study_Session__c> data = (List<reduivy__Study_Session__c>) JSON.deserialize(response.responseData, List<reduivy__Study_Session__c>.class);
                
                Integer count = sseCount.containsKey(sof.Id) ? sseCount.get(sof.Id) : 0;
                System.Assert.areEqual(count, data.size(), 'The response study session list length should be same.');
            }
            
        }

        Test.stopTest();
    }

    /**
     * @description Test as admin for REDU_IpePathwayStudySessions_LCTRL.getStudySessions() with null param
     */
    @IsTest
    static void testGetStudySessionNullParamAsAdmin(){

        Test.startTest();
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            
            try{
                REDU_LightningResponse response = REDU_IpePathwayStudySessions_LCTRL.getStudySessions(null);
                System.Assert.fail('This should be failed to get response.');

            } catch(Exception ex) {
                System.assertEquals(true, ex.getMessage().contains(Label.Error_Contact_Admin), 'Expected error messages should match. ex.getMessage() :: ' + ex.getMessage());
            }
        }

        Test.stopTest();
        
    }
}