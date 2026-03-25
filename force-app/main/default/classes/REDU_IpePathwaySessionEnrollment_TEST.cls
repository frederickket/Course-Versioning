/**
 * @author      WDCi (Sueanne)
 * @date        Sept 2024
 * @group       Test
 * @description Test class for REDU_IpePathwaySessionEnrollment_LCTRL
 * @changehistory
 * ISS-002050 25-09-2024 Sueanne - new class
 */
@IsTest
public inherited sharing class REDU_IpePathwaySessionEnrollment_TEST {

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
     * @description Test as admin for REDU_IpePathwaySessionEnrollment_LCTRL.getStudyOfferings()
     */
    @IsTest
    static void testGetStudyOfferingAsAdmin(){

        Test.startTest();
        User ADMIN_USER = testFactory.getReduAdminUser();

        Map<Id, reduivy__Individual_Pathway__c> ipwByIpeMap = new Map<Id, reduivy__Individual_Pathway__c>();
        Set<Id> contactIds = new Set<Id>();
        Set<Id> termIds = new Set<Id>();
        
        for(reduivy__Individual_Pathway__c ipw : [SELECT Id,
            reduivy__Individual_Program_Enrollment__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Academic_Term__c,
            reduivy__Status__c
            FROM reduivy__Individual_Pathway__c
            WHERE reduivy__Individual_Program_Enrollment__r.RecordTypeId = :IPE_Helper.getMasterEnrollmentRecordTypeId()
        ]){
            ipwByIpeMap.put(ipw.reduivy__Individual_Program_Enrollment__c, ipw);
            contactIds.add(ipw.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c);
            termIds.add(ipw.reduivy__Academic_Term__c);
        }
        
        Set<String> ienStatuses = new Set<String>();
        ienStatuses.addAll(IEN_Helper.getInProgressStatuses());
        ienStatuses.addAll(IEN_Helper.getCompletedStatuses());
            
        //count sof
        Map<String, Integer> sofCountMap = new Map<String, Integer>();
        Map<String, List<Id>> sofIdsMap = new Map<String, List<Id>>();
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Study_Offering__c, reduivy__Contact__c, reduivy__Academic_Term_Id__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Enrollment_Status__c IN :ienStatuses
            AND reduivy__Contact__c IN :contactIds
            AND reduivy__Academic_Term_Id__c IN :termIds
        ]){
            String key = ien.reduivy__Contact__c + '_' + ien.reduivy__Academic_Term_Id__c; 
            if (sofCountMap.containsKey(key)) {
                sofCountMap.put(key, sofCountMap.get(key) + 1);
            } else {
                sofCountMap.put(key, 1);
            }

            if (!sofIdsMap.containsKey(key)){
                sofIdsMap.put(key, new List<Id>());
            }
            sofIdsMap.get(key).add(ien.reduivy__Study_Offering__c);
        }

        System.runAs(ADMIN_USER){
            
            for(Id ipeId : ipwByIpeMap.keySet()){
                reduivy__Individual_Pathway__c ipw = ipwByIpeMap.get(ipeId);

                REDU_LightningResponse response = REDU_IpePathwaySessionEnrollment_LCTRL.getStudyOfferings(ipeId, ipw.Id, '');
                System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_IpePathwaySessionEnrollment_TEST');

                String key = ipw.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c + '_' + ipw.reduivy__Academic_Term__c; 
                Map<Id, reduivy__Study_Offering__c> data = (Map<Id, reduivy__Study_Offering__c>) JSON.deserialize(response.responseData, Map<Id, reduivy__Study_Offering__c>.class);
                Integer count = sofCountMap.containsKey(key) ? sofCountMap.get(key) : 0;
                System.Assert.areEqual(count, data.size(), 'The response study offering list length should be same.');

                for(reduivy__Study_Offering__c sof : data.values()){
                    System.Assert.areEqual(true, sofIdsMap.get(key).contains(sof.Id), 'The study offering Id should include in sofIdsMap.');
                }
            }

        }

        Test.stopTest();
        
    }

    /**
     * @description Test as faculty for REDU_IpePathwaySessionEnrollment_LCTRL.getStudyOfferings()
     */
    @IsTest
    static void testGetStudyOfferingAsFaculty(){

        Test.startTest();
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Map<Id, reduivy__Individual_Pathway__c> ipwByIpeMap = new Map<Id, reduivy__Individual_Pathway__c>();
        Set<Id> contactIds = new Set<Id>();
        Set<Id> termIds = new Set<Id>();
        
        for(reduivy__Individual_Pathway__c ipw : [SELECT Id,
            reduivy__Individual_Program_Enrollment__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Academic_Term__c,
            reduivy__Status__c
            FROM reduivy__Individual_Pathway__c
            WHERE reduivy__Individual_Program_Enrollment__r.RecordTypeId = :IPE_Helper.getMasterEnrollmentRecordTypeId()
        ]){
            ipwByIpeMap.put(ipw.reduivy__Individual_Program_Enrollment__c, ipw);
            contactIds.add(ipw.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c);
            termIds.add(ipw.reduivy__Academic_Term__c);
        }
        
        Set<String> ienStatuses = new Set<String>();
        ienStatuses.addAll(IEN_Helper.getInProgressStatuses());
        ienStatuses.addAll(IEN_Helper.getCompletedStatuses());
            
        //count sof
        Map<String, Integer> sofCountMap = new Map<String, Integer>();
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Study_Offering__c, reduivy__Contact__c, reduivy__Academic_Term_Id__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Enrollment_Status__c IN :ienStatuses
            AND reduivy__Contact__c IN :contactIds
            AND reduivy__Academic_Term_Id__c IN :termIds
        ]){
            String key = ien.reduivy__Contact__c + '_' + ien.reduivy__Academic_Term_Id__c; 
            if (sofCountMap.containsKey(key)) {
                sofCountMap.put(key, sofCountMap.get(key) + 1);
            } else {
                sofCountMap.put(key, 1);
            }

        }

        System.runAs(FACULTY_USER){
            
            for(Id ipeId : ipwByIpeMap.keySet()){
                reduivy__Individual_Pathway__c ipw = ipwByIpeMap.get(ipeId);

                REDU_LightningResponse response = REDU_IpePathwaySessionEnrollment_LCTRL.getStudyOfferings(ipeId, ipw.Id, 'Name');
                System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_IpePathwaySessionEnrollment_TEST');

                String key = ipw.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c + '_' + ipw.reduivy__Academic_Term__c; 
                Map<Id, reduivy__Study_Offering__c> data = (Map<Id, reduivy__Study_Offering__c>) JSON.deserialize(response.responseData, Map<Id, reduivy__Study_Offering__c>.class);
                Integer count = sofCountMap.containsKey(key) ? sofCountMap.get(key) : 0;
                System.Assert.areEqual(count, data.size(), 'The response study offering list length should be same.');
            }

        }

        Test.stopTest();
        
    }

    /**
     * @description Test as student for REDU_IpePathwaySessionEnrollment_LCTRL.getStudyOfferings()
     */
    @IsTest
    static void testGetStudyOfferingAsStudent(){

        Test.startTest();

        User studentUser = testFactory.getStudentUser();

        Map<Id, reduivy__Individual_Pathway__c> ipwByIpeMap = new Map<Id, reduivy__Individual_Pathway__c>();
        Set<Id> contactIds = new Set<Id>();
        Set<Id> termIds = new Set<Id>();
        
        for(reduivy__Individual_Pathway__c ipw : [SELECT Id,
            reduivy__Individual_Program_Enrollment__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
            reduivy__Academic_Term__c,
            reduivy__Status__c
            FROM reduivy__Individual_Pathway__c
            WHERE reduivy__Individual_Program_Enrollment__r.RecordTypeId = :IPE_Helper.getMasterEnrollmentRecordTypeId()
            AND reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c = :studentUser.ContactId
        ]){
            ipwByIpeMap.put(ipw.reduivy__Individual_Program_Enrollment__c, ipw);
            contactIds.add(ipw.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c);
            termIds.add(ipw.reduivy__Academic_Term__c);
        }
        
        Set<String> ienStatuses = new Set<String>();
        ienStatuses.addAll(IEN_Helper.getInProgressStatuses());
        ienStatuses.addAll(IEN_Helper.getCompletedStatuses());
            
        //count sof
        Map<String, Integer> sofCountMap = new Map<String, Integer>();
        for(reduivy__Individual_Enrollment__c ien : [
            SELECT Id, reduivy__Study_Offering__c, reduivy__Contact__c, reduivy__Academic_Term_Id__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Enrollment_Status__c IN :ienStatuses
            AND reduivy__Contact__c IN :contactIds
            AND reduivy__Academic_Term_Id__c IN :termIds
        ]){
            String key = ien.reduivy__Contact__c + '_' + ien.reduivy__Academic_Term_Id__c; 
            if (sofCountMap.containsKey(key)) {
                sofCountMap.put(key, sofCountMap.get(key) + 1);
            } else {
                sofCountMap.put(key, 1);
            }

        }

        System.runAs(studentUser){
            
            for(Id ipeId : ipwByIpeMap.keySet()){
                reduivy__Individual_Pathway__c ipw = ipwByIpeMap.get(ipeId);

                REDU_LightningResponse response = REDU_IpePathwaySessionEnrollment_LCTRL.getStudyOfferings(ipeId, ipw.Id, 'Name');
                System.Assert.areEqual(true, response.isSuccess, 'Failed to get response from REDU_IpePathwaySessionEnrollment_TEST');

                String key = ipw.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c + '_' + ipw.reduivy__Academic_Term__c; 
                Map<Id, reduivy__Study_Offering__c> data = (Map<Id, reduivy__Study_Offering__c>) JSON.deserialize(response.responseData, Map<Id, reduivy__Study_Offering__c>.class);
                Integer count = sofCountMap.containsKey(key) ? sofCountMap.get(key) : 0;
                System.Assert.areEqual(count, data.size(), 'The response study offering list length should be same.');
            }

        }

        Test.stopTest();
        
    }

    /**
     * @description Test as admin for REDU_IpePathwaySessionEnrollment_LCTRL.getStudyOfferings() with null param
     */
    @IsTest
    static void testGetStudyOfferingNullParamAsAdmin(){

        Test.startTest();
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            
            try{
                REDU_LightningResponse response = REDU_IpePathwaySessionEnrollment_LCTRL.getStudyOfferings(null, null, '');
                System.Assert.fail('This should be failed to get response.');

            } catch(AuraHandledException ex) {
                System.assertEquals(true, ex.getMessage().contains(Label.Error_Contact_Admin), 'Expected error messages should match.');
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test as admin for REDU_IpePathwaySessionEnrollment_LCTRL.getStudyOfferings() with invalid ipe param
     */
    @IsTest
    static void testGetStudyOfferingInvalidIpeIdAsAdmin(){

        Test.startTest();
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER){
            
            Id invalidId = 'a0JDJ000111nehN2AQ';
            try{
                REDU_LightningResponse response = REDU_IpePathwaySessionEnrollment_LCTRL.getStudyOfferings(invalidId, invalidId, 'Name');
                System.Assert.fail('This should be failed to get response.');

            } catch(Exception ex) {
                String errMsg = String.format(Label.Invalid_Record_Id_For_Object_Type, new List<String>{invalidId, IPE_Helper.getObjectLabel()});
                System.assertEquals(true, ex.getMessage().contains(errMsg), 'Expected error messages should match. ');
            }
        }

        Test.stopTest();
        
    }

    /**
     * @description Test as admin for REDU_IpePathwaySessionEnrollment_LCTRL.getStudyOfferings() with invalid ipw param
     */
    @IsTest
    static void testGetStudyOfferingInvalidIpwIdAsAdmin(){

        Test.startTest();
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Individual_Program_Enrollment__c ipe = [
            SELECT Id, reduivy__Contact__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE RecordTypeId = :IPE_Helper.getMasterEnrollmentRecordTypeId()
            LIMIT 1
        ];

        System.runAs(ADMIN_USER){
            
            Id invalidId = 'a0JDJ000111nehN2AQ';
            try{
                REDU_LightningResponse response = REDU_IpePathwaySessionEnrollment_LCTRL.getStudyOfferings(ipe.Id, invalidId, 'Name');
                System.Assert.fail('This should be failed to get response.');

            } catch(Exception ex) {
                String errMsg = String.format(Label.Invalid_Record_Id_For_Object_Type, new List<String>{invalidId, IPW_Helper.getObjectLabel()});
                System.assertEquals(true, ex.getMessage().contains(errMsg), 'Expected error messages should match.');
            }
        }

        Test.stopTest();
        
    }
}