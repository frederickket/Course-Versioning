/**
 * @author      WDCi (Jordan)
 * @date        Nov 2023
 * @group       Test
 * @description Test class for REDU_IpePathwayTermSelection_LCTRL
 * @changehistory
 * ISS-002367 11-04-2025 XW - added test methods for AcademicTermPastStartDate
 */
@isTest
public inherited sharing class REDU_IpePathwayTermSelection_TEST {

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
        
        // Create test data
        User ADMIN_USER = testFactory.getReduAdminUser();
        System.runAs(ADMIN_USER) {
            Test.startTest();

            testFactory.initMasterData(null);
			testFactory.initOfferingData(SIT_Helper.getApiName());
			testFactory.initStudentData(IPE_Helper.getApiName(), true);

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin for REDU_IpePathwayTermSelection_LCTRL
     */
    @isTest   
    static void testForAdmin() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];

        Id eduInstId;
        Set<Id> selectedAcademicTermIds = new Set<Id>();

        List<reduivy__Individual_Pathway__c> ipwList = [SELECT Id,
            reduivy__Academic_Term__c,
            reduivy__Individual_Program_Enrollment__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Study_Program__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Study_Program__r.reduivy__Educational_Institution__c
            FROM reduivy__Individual_Pathway__c
            WHERE reduivy__Individual_Program_Enrollment__c =: masterIPE.Id
        ];

        for (reduivy__Individual_Pathway__c ipw : ipwList) {
            eduInstId = ipw.reduivy__Individual_Program_Enrollment__r.reduivy__Study_Program__r.reduivy__Educational_Institution__c;
            if (String.isNotBlank(ipw.reduivy__Academic_Term__c)) {
                selectedAcademicTermIds.add(ipw.reduivy__Academic_Term__c);
            }
        }

        List<reduivy__Study_Term__c> availableTerms = new List<reduivy__Study_Term__c>();
        for (reduivy__Study_Term__c term : [SELECT Id,
            reduivy__Start_Date__c,
            reduivy__End_Date__c,
            reduivy__For_Internal_Only__c,
            reduivy__Display_Name__c
            FROM reduivy__Study_Term__c
            WHERE reduivy__Academic_Year__r.reduivy__Educational_Institution__c =: eduInstId
            AND RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId()
            AND reduivy__End_Date__c >= TODAY
            ORDER BY reduivy__Start_Date__c, reduivy__Display_Name__c 
        ]) {
            if (!selectedAcademicTermIds.contains(term.Id)) {
                availableTerms.add(term);
            }
        }

        System.runAs(ADMIN_USER){
            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathwayTermSelection_LCTRL.getAcademicTerms(masterIPE.Id);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermSelection_TEST');

            List<reduivy__Study_Term__c> availableTermsResponse = (List<reduivy__Study_Term__c>) JSON.deserialize(objResponse.responseData, List<reduivy__Study_Term__c>.class);
            System.Assert.areEqual(availableTerms.size(), availableTermsResponse.size());

            Test.stopTest();
        }
    }

    /**
     * @description Test as admin for REDU_IpePathwayTermSelection_LCTRL
     */
    @isTest   
    static void testForAdminNoEduInst() {

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];

        System.runAs(ADMIN_USER){
            //Clear EduInst field
            List<reduivy__Study_Program__c> spList = [SELECT reduivy__Educational_Institution__c
                FROM reduivy__Study_Program__c
            ];

            for (reduivy__Study_Program__c sp : spList) {
                sp.reduivy__Educational_Institution__c = null;
            }

            update spList;

            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathwayTermSelection_LCTRL.getAcademicTerms(masterIPE.Id);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermSelection_TEST');
            System.Assert.areEqual(null, objResponse.responseData);

            Test.stopTest();
        }
    }


    /**
     * @description Test as admin for REDU_IpePathwayTermSelection_LCTRL, the study term that has past start date but not end date should not be queried
     */
    @IsTest
    static void testForAdminAcademicTermPastStartDate() {
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];

        Id eduInstId;
        Set<Id> selectedAcademicTermIds = new Set<Id>();

        List<reduivy__Individual_Pathway__c> ipwList = [SELECT Id,
            reduivy__Academic_Term__c,
            reduivy__Academic_Term__r.reduivy__Start_Date__c,
            reduivy__Individual_Program_Enrollment__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Study_Program__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Study_Program__r.reduivy__Educational_Institution__c
            FROM reduivy__Individual_Pathway__c
            WHERE reduivy__Individual_Program_Enrollment__c =: masterIPE.Id
            ORDER BY reduivy__Academic_Term__r.reduivy__Start_Date__c NULLS LAST
        ];

        Date greatestStartDate;
        for (reduivy__Individual_Pathway__c ipw : ipwList) {
            eduInstId = ipw.reduivy__Individual_Program_Enrollment__r.reduivy__Study_Program__r.reduivy__Educational_Institution__c;
            if (String.isNotBlank(ipw.reduivy__Academic_Term__c)) {
                selectedAcademicTermIds.add(ipw.reduivy__Academic_Term__c);
            }
            if(greatestStartDate == null) {
                greatestStartDate = ipw.reduivy__Academic_Term__r.reduivy__Start_Date__c;
            }
        }

        //create academic term that has past start date but not end date
        reduivy__Study_Term__c pastStm  = new reduivy__Study_Term__c();
        pastStm.Name = 'pastStm';
        pastStm.reduivy__Start_Date__c = greatestStartDate.addDays(-1);
        pastStm.reduivy__End_Date__c = Date.today().addMonths(1);

        insert pastStm;

        List<reduivy__Study_Term__c> availableTerms = new List<reduivy__Study_Term__c>();
        for (reduivy__Study_Term__c term : [SELECT Id,
            reduivy__Start_Date__c,
            reduivy__End_Date__c,
            reduivy__For_Internal_Only__c,
            reduivy__Display_Name__c
            FROM reduivy__Study_Term__c
            WHERE reduivy__Academic_Year__r.reduivy__Educational_Institution__c =: eduInstId
            AND RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId()
            AND reduivy__End_Date__c >= TODAY
            AND reduivy__Start_Date__c > :greatestStartDate
            ORDER BY reduivy__Start_Date__c, reduivy__Display_Name__c 
        ]) {
            if (!selectedAcademicTermIds.contains(term.Id)) {
                availableTerms.add(term);
            }
        }

        System.runAs(ADMIN_USER){
            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathwayTermSelection_LCTRL.getAcademicTerms(masterIPE.Id);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermSelection_TEST');

            List<reduivy__Study_Term__c> availableTermsResponse = (List<reduivy__Study_Term__c>) JSON.deserialize(objResponse.responseData, List<reduivy__Study_Term__c>.class);
            System.Assert.areEqual(availableTerms.size(), availableTermsResponse.size());
            
            for(reduivy__Study_Term__c stmResponse : availableTermsResponse) {
                System.Assert.areNotEqual('pastStm', stmResponse.Name, 'Academic Term that has earlier start date than the previous term shouldnt be queried!');
            }

            Test.stopTest();
        }
    }

    /**
     * @description Test as student user for REDU_IpePathwayTermSelection_LCTRL
     */
    @isTest   
    static void testForStudentUser() {

        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        User studentUser = [SELECT Id, ContactId, ProfileId FROM User WHERE ContactId = : masterIPE.reduivy__Contact__c];

        Id eduInstId;
        Set<Id> selectedAcademicTermIds = new Set<Id>();

        List<reduivy__Individual_Pathway__c> ipwList = [SELECT Id,
            reduivy__Academic_Term__c,
            reduivy__Individual_Program_Enrollment__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Study_Program__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Study_Program__r.reduivy__Educational_Institution__c
            FROM reduivy__Individual_Pathway__c
            WHERE reduivy__Individual_Program_Enrollment__c =: masterIPE.Id
        ];

        for (reduivy__Individual_Pathway__c ipw : ipwList) {
            eduInstId = ipw.reduivy__Individual_Program_Enrollment__r.reduivy__Study_Program__r.reduivy__Educational_Institution__c;
            if (String.isNotBlank(ipw.reduivy__Academic_Term__c)) {
                selectedAcademicTermIds.add(ipw.reduivy__Academic_Term__c);
            }
        }

        List<reduivy__Study_Term__c> availableTerms = new List<reduivy__Study_Term__c>();
        for (reduivy__Study_Term__c term : [SELECT Id,
            reduivy__Start_Date__c,
            reduivy__End_Date__c,
            reduivy__For_Internal_Only__c,
            reduivy__Display_Name__c
            FROM reduivy__Study_Term__c
            WHERE reduivy__Academic_Year__r.reduivy__Educational_Institution__c =: eduInstId
            AND RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId()
            AND reduivy__End_Date__c >= TODAY
            ORDER BY reduivy__Start_Date__c, reduivy__Display_Name__c 
        ]) {
            if (!selectedAcademicTermIds.contains(term.Id)) {
                availableTerms.add(term);
            }
        }

        System.runAs(studentUser){
            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathwayTermSelection_LCTRL.getAcademicTerms(masterIPE.Id);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermSelection_TEST');

            List<reduivy__Study_Term__c> availableTermsResponse = (List<reduivy__Study_Term__c>) JSON.deserialize(objResponse.responseData, List<reduivy__Study_Term__c>.class);
            System.Assert.areEqual(availableTerms.size(), availableTermsResponse.size());

            Test.stopTest();
        }
    }

    /**
     * @description Test as student for REDU_IpePathwayTermSelection_LCTRL
     */
    @isTest   
    static void testForStudentNoEduInst() {

        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        User studentUser = [SELECT Id, ContactId, ProfileId FROM User WHERE ContactId = : masterIPE.reduivy__Contact__c];

        //Clear EduInst field
        List<reduivy__Study_Program__c> spList = [SELECT reduivy__Educational_Institution__c
            FROM reduivy__Study_Program__c
        ];

        for (reduivy__Study_Program__c sp : spList) {
            sp.reduivy__Educational_Institution__c = null;
        }

        update spList;
        
        System.runAs(studentUser){

            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathwayTermSelection_LCTRL.getAcademicTerms(masterIPE.Id);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermSelection_TEST');
            System.Assert.areEqual(null, objResponse.responseData);

            Test.stopTest();
        }
    }

    /**
     * @description Test as student for REDU_IpePathwayTermSelection_LCTRL, the study term that has past start date but not end date should not be queried
     */
    @IsTest
    static void testForStudentAcademicTermPastStartDate() {
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        User studentUser = [SELECT Id, ContactId, ProfileId FROM User WHERE ContactId = : masterIPE.reduivy__Contact__c];

        Id eduInstId;
        Set<Id> selectedAcademicTermIds = new Set<Id>();

        List<reduivy__Individual_Pathway__c> ipwList = [SELECT Id,
            reduivy__Academic_Term__c,
            reduivy__Academic_Term__r.reduivy__Start_Date__c,
            reduivy__Individual_Program_Enrollment__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Study_Program__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Study_Program__r.reduivy__Educational_Institution__c
            FROM reduivy__Individual_Pathway__c
            WHERE reduivy__Individual_Program_Enrollment__c =: masterIPE.Id
            ORDER BY reduivy__Academic_Term__r.reduivy__Start_Date__c NULLS LAST
        ];

        Date greatestStartDate;
        for (reduivy__Individual_Pathway__c ipw : ipwList) {
            eduInstId = ipw.reduivy__Individual_Program_Enrollment__r.reduivy__Study_Program__r.reduivy__Educational_Institution__c;
            if (String.isNotBlank(ipw.reduivy__Academic_Term__c)) {
                selectedAcademicTermIds.add(ipw.reduivy__Academic_Term__c);
            }
            if(greatestStartDate == null) {
                greatestStartDate = ipw.reduivy__Academic_Term__r.reduivy__Start_Date__c;
            }
        }

        //create academic term that has past start date but not end date
        reduivy__Study_Term__c pastStm  = new reduivy__Study_Term__c();
        pastStm.Name = 'pastStm';
        pastStm.reduivy__Start_Date__c = greatestStartDate.addDays(-1);
        pastStm.reduivy__End_Date__c = Date.today().addMonths(1);

        insert pastStm;

        List<reduivy__Study_Term__c> availableTerms = new List<reduivy__Study_Term__c>();
        for (reduivy__Study_Term__c term : [SELECT Id,
            reduivy__Start_Date__c,
            reduivy__End_Date__c,
            reduivy__For_Internal_Only__c,
            reduivy__Display_Name__c
            FROM reduivy__Study_Term__c
            WHERE reduivy__Academic_Year__r.reduivy__Educational_Institution__c =: eduInstId
            AND RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId()
            AND reduivy__End_Date__c >= TODAY
            AND reduivy__Start_Date__c > :greatestStartDate
            ORDER BY reduivy__Start_Date__c, reduivy__Display_Name__c 
        ]) {
            if (!selectedAcademicTermIds.contains(term.Id)) {
                availableTerms.add(term);
            }
        }

        System.runAs(studentUser){
            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathwayTermSelection_LCTRL.getAcademicTerms(masterIPE.Id);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermSelection_TEST');

            List<reduivy__Study_Term__c> availableTermsResponse = (List<reduivy__Study_Term__c>) JSON.deserialize(objResponse.responseData, List<reduivy__Study_Term__c>.class);
            System.Assert.areEqual(availableTerms.size(), availableTermsResponse.size());
            
            for(reduivy__Study_Term__c stmResponse : availableTermsResponse) {
                System.Assert.areNotEqual('pastStm', stmResponse.Name, 'Academic Term that has earlier start date than the previous term shouldnt be queried!');
            }

            Test.stopTest();
        }
    }


    /**
     * @description Test as faculty user for REDU_IpePathwayTermSelection_LCTRL
     */
    @isTest   
    static void testForFacultyUser() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];

        Id eduInstId;
        Set<Id> selectedAcademicTermIds = new Set<Id>();

        List<reduivy__Individual_Pathway__c> ipwList = [SELECT Id,
            reduivy__Academic_Term__c,
            reduivy__Individual_Program_Enrollment__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Study_Program__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Study_Program__r.reduivy__Educational_Institution__c
            FROM reduivy__Individual_Pathway__c
            WHERE reduivy__Individual_Program_Enrollment__c =: masterIPE.Id
        ];

        for (reduivy__Individual_Pathway__c ipw : ipwList) {
            eduInstId = ipw.reduivy__Individual_Program_Enrollment__r.reduivy__Study_Program__r.reduivy__Educational_Institution__c;
            if (String.isNotBlank(ipw.reduivy__Academic_Term__c)) {
                selectedAcademicTermIds.add(ipw.reduivy__Academic_Term__c);
            }
        }

        List<reduivy__Study_Term__c> availableTerms = new List<reduivy__Study_Term__c>();
        for (reduivy__Study_Term__c term : [SELECT Id,
            reduivy__Start_Date__c,
            reduivy__End_Date__c,
            reduivy__For_Internal_Only__c,
            reduivy__Display_Name__c
            FROM reduivy__Study_Term__c
            WHERE reduivy__Academic_Year__r.reduivy__Educational_Institution__c =: eduInstId
            AND RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId()
            AND reduivy__End_Date__c >= TODAY
            ORDER BY reduivy__Start_Date__c, reduivy__Display_Name__c 
        ]) {
            if (!selectedAcademicTermIds.contains(term.Id)) {
                availableTerms.add(term);
            }
        }

        System.runAs(FACULTY_USER){

            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathwayTermSelection_LCTRL.getAcademicTerms(masterIPE.Id);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermSelection_TEST');

            List<reduivy__Study_Term__c> availableTermsResponse = (List<reduivy__Study_Term__c>) JSON.deserialize(objResponse.responseData, List<reduivy__Study_Term__c>.class);
            System.Assert.areEqual(availableTerms.size(), availableTermsResponse.size());

            Test.stopTest();
        }
    }

    /**
     * @description Test as faculty for REDU_IpePathwayTermSelection_LCTRL
     */
    @isTest   
    static void testForFacultyNoEduInst() {
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id, reduivy__Contact__c FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        
        System.runAs(FACULTY_USER){
            //Clear EduInst field
            List<reduivy__Study_Program__c> spList = [SELECT reduivy__Educational_Institution__c
                FROM reduivy__Study_Program__c
            ];

            for (reduivy__Study_Program__c sp : spList) {
                sp.reduivy__Educational_Institution__c = null;
            }

            update spList;

            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathwayTermSelection_LCTRL.getAcademicTerms(masterIPE.Id);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermSelection_TEST');
            System.Assert.areEqual(null, objResponse.responseData);

            Test.stopTest();
        }
    }


    /**
     * @description Test as faculty for REDU_IpePathwayTermSelection_LCTRL, the study term that has past start date but not end date should not be queried
     */
    @IsTest
    static void testForFacultyAcademicTermPastStartDate() {
        
        reduivy__Individual_Program_Enrollment__c masterIPE = [SELECT Id FROM reduivy__Individual_Program_Enrollment__c WHERE RecordTypeId = : IPE_Helper.getMasterEnrollmentRecordTypeId() LIMIT 1];
        
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Id eduInstId;
        Set<Id> selectedAcademicTermIds = new Set<Id>();

        List<reduivy__Individual_Pathway__c> ipwList = [SELECT Id,
            reduivy__Academic_Term__c,
            reduivy__Academic_Term__r.reduivy__Start_Date__c,
            reduivy__Individual_Program_Enrollment__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Study_Program__c,
            reduivy__Individual_Program_Enrollment__r.reduivy__Study_Program__r.reduivy__Educational_Institution__c
            FROM reduivy__Individual_Pathway__c
            WHERE reduivy__Individual_Program_Enrollment__c =: masterIPE.Id
            ORDER BY reduivy__Academic_Term__r.reduivy__Start_Date__c NULLS LAST
        ];

        Date greatestStartDate;
        for (reduivy__Individual_Pathway__c ipw : ipwList) {
            eduInstId = ipw.reduivy__Individual_Program_Enrollment__r.reduivy__Study_Program__r.reduivy__Educational_Institution__c;
            if (String.isNotBlank(ipw.reduivy__Academic_Term__c)) {
                selectedAcademicTermIds.add(ipw.reduivy__Academic_Term__c);
            }
            if(greatestStartDate == null) {
                greatestStartDate = ipw.reduivy__Academic_Term__r.reduivy__Start_Date__c;
            }
        }

        //create academic term that has past start date but not end date
        reduivy__Study_Term__c pastStm  = new reduivy__Study_Term__c();
        pastStm.Name = 'pastStm';
        pastStm.reduivy__Start_Date__c = greatestStartDate.addDays(-1);
        pastStm.reduivy__End_Date__c = Date.today().addMonths(1);

        insert pastStm;

        List<reduivy__Study_Term__c> availableTerms = new List<reduivy__Study_Term__c>();
        for (reduivy__Study_Term__c term : [SELECT Id,
            reduivy__Start_Date__c,
            reduivy__End_Date__c,
            reduivy__For_Internal_Only__c,
            reduivy__Display_Name__c
            FROM reduivy__Study_Term__c
            WHERE reduivy__Academic_Year__r.reduivy__Educational_Institution__c =: eduInstId
            AND RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId()
            AND reduivy__End_Date__c >= TODAY
            AND reduivy__Start_Date__c > :greatestStartDate
            ORDER BY reduivy__Start_Date__c, reduivy__Display_Name__c 
        ]) {
            if (!selectedAcademicTermIds.contains(term.Id)) {
                availableTerms.add(term);
            }
        }

        System.runAs(FACULTY_USER){
            Test.startTest();

            REDU_LightningResponse objResponse = REDU_IpePathwayTermSelection_LCTRL.getAcademicTerms(masterIPE.Id);
            System.Assert.areEqual(true, objResponse.isSuccess, 'Failed to get response from REDU_IpePathwayTermSelection_TEST');

            List<reduivy__Study_Term__c> availableTermsResponse = (List<reduivy__Study_Term__c>) JSON.deserialize(objResponse.responseData, List<reduivy__Study_Term__c>.class);
            System.Assert.areEqual(availableTerms.size(), availableTermsResponse.size());
            
            for(reduivy__Study_Term__c stmResponse : availableTermsResponse) {
                System.Assert.areNotEqual('pastStm', stmResponse.Name, 'Academic Term that has earlier start date than the previous term shouldnt be queried!');
            }

            Test.stopTest();
        }
    }


}