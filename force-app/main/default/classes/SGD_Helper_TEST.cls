/**
 * @author      WDCi (Lean)
 * @date        Jan 2024
 * @group       Test
 * @description Test class for SGD_Helper
 * @changehistory
 * ISS-002486 XiRouh - Introduce New IEN Status: Completed – Failed
 */
@IsTest
public inherited sharing class SGD_Helper_TEST {
    
    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
    
    /**
     * @description Initialise test data for each test
     */
    @testSetup
    static void setupTestData() {
        testFactory.setupDefaultSettings();
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        System.runAs(ADMIN_USER) {
            Test.startTest();

            testFactory.initMasterData(SGD_Helper.getApiName());

            Test.stopTest();
        }
    }

    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Study_Grading_Scheme__c.getLabel(), SGD_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Grading_Scheme__c.getLabelPlural(), SGD_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Grading_Scheme__c.getName(), SGD_Helper.getApiName());

        Test.stopTest();
        
    }
    
    @IsTest
    static void testMatchByNumPositive(){
        
        Test.startTest();
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            reduivy__Study_Grade_Setting__c sgs = [SELECT Id FROM reduivy__Study_Grade_Setting__c WHERE reduivy__Sample_Record_Code__c = 'PERCENTAGE_SCORE'];

            Map<Id, List<reduivy__Study_Grading_Scheme__c>> sgsScheme = SGD_Helper.getStudyGradingSchemes(new Set<Id>{sgs.Id}, false);

            Map<String, Object> matchByNum = SGD_Helper.matchGradingScheme(90, null, sgsScheme.get(sgs.Id), IEN_Helper.ATTENDANCE_REQUIREMENT_MET_YES);
            System.Assert.isTrue(matchByNum != null, 'There should be 1 match');
            System.Assert.areEqual('A', (String) matchByNum.get('reduivy__Letter_Grade__c'));
            System.Assert.areEqual(100, (Decimal) matchByNum.get('reduivy__Numerical_Grade__c'));
            System.Assert.areEqual(4, (Decimal) matchByNum.get('reduivy__Grade_Points__c'));
            System.Assert.areEqual('Pass', (String) matchByNum.get('reduivy__Grade_Result__c'));
            System.Assert.areEqual('No', (String) matchByNum.get('reduivy__Exclude_Credits_Earned__c'));
            System.Assert.areEqual('No', (String) matchByNum.get('reduivy__Exclude_GPA_Calculation__c'));
            System.Assert.areEqual('Completed', (String) matchByNum.get('reduivy__Enrollment_Status__c'));
        }

        Test.stopTest();
        
    }

    @IsTest
    static void testMatchByNumAbsent(){
        
        Test.startTest();
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            reduivy__Study_Grade_Setting__c sgs = [SELECT Id FROM reduivy__Study_Grade_Setting__c WHERE reduivy__Sample_Record_Code__c = 'PERCENTAGE_SCORE'];

            Map<Id, List<reduivy__Study_Grading_Scheme__c>> sgsScheme = SGD_Helper.getStudyGradingSchemes(new Set<Id>{sgs.Id}, false);

            Map<String, Object> matchByNum = SGD_Helper.matchGradingScheme(90, null, sgsScheme.get(sgs.Id), IEN_Helper.ATTENDANCE_REQUIREMENT_MET_NO);
            System.Assert.isTrue(matchByNum != null, 'There should be 1 match');
            System.Assert.areEqual('FA', (String) matchByNum.get('reduivy__Letter_Grade__c'));
            System.Assert.areEqual(null, (Decimal) matchByNum.get('reduivy__Numerical_Grade__c'));
            System.Assert.areEqual(0, (Decimal) matchByNum.get('reduivy__Grade_Points__c'));
            System.Assert.areEqual('Fail', (String) matchByNum.get('reduivy__Grade_Result__c'));
            System.Assert.areEqual('No', (String) matchByNum.get('reduivy__Exclude_Credits_Earned__c'));
            System.Assert.areEqual('No', (String) matchByNum.get('reduivy__Exclude_GPA_Calculation__c'));
            System.Assert.areEqual('Completed Fail', (String) matchByNum.get('reduivy__Enrollment_Status__c'));
        }

        Test.stopTest();
        
    }

    @IsTest
    static void testMatchByNumNegative(){
        
        Test.startTest();
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            reduivy__Study_Grade_Setting__c sgs = [SELECT Id FROM reduivy__Study_Grade_Setting__c WHERE reduivy__Sample_Record_Code__c = 'PERCENTAGE_SCORE'];

            Map<Id, List<reduivy__Study_Grading_Scheme__c>> sgsScheme = SGD_Helper.getStudyGradingSchemes(new Set<Id>{sgs.Id}, false);

            Map<String, Object> matchByNum = SGD_Helper.matchGradingScheme(-1, null, sgsScheme.get(sgs.Id), IEN_Helper.ATTENDANCE_REQUIREMENT_MET_YES);
            System.Assert.isTrue(matchByNum == null, 'There should be 0 match');
        }

        Test.stopTest();
        
    }

    @IsTest
    static void testMatchByLetterPositive(){
        
        Test.startTest();
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            reduivy__Study_Grade_Setting__c sgs = [SELECT Id FROM reduivy__Study_Grade_Setting__c WHERE reduivy__Sample_Record_Code__c = 'PERCENTAGE_SCORE'];

            Map<Id, List<reduivy__Study_Grading_Scheme__c>> sgsScheme = SGD_Helper.getStudyGradingSchemes(new Set<Id>{sgs.Id}, false);

            Map<String, Object> matchByNum = SGD_Helper.matchGradingScheme(null, 'A', sgsScheme.get(sgs.Id), IEN_Helper.ATTENDANCE_REQUIREMENT_MET_YES);
            System.Assert.isTrue(matchByNum != null, 'There should be 1 match');
            System.Assert.areEqual('A', (String) matchByNum.get('reduivy__Letter_Grade__c'));
            System.Assert.areEqual(100, (Decimal) matchByNum.get('reduivy__Numerical_Grade__c'));
            System.Assert.areEqual(4, (Decimal) matchByNum.get('reduivy__Grade_Points__c'));
            System.Assert.areEqual('Pass', (String) matchByNum.get('reduivy__Grade_Result__c'));
            System.Assert.areEqual('No', (String) matchByNum.get('reduivy__Exclude_Credits_Earned__c'));
            System.Assert.areEqual('No', (String) matchByNum.get('reduivy__Exclude_GPA_Calculation__c'));
            System.Assert.areEqual('Completed', (String) matchByNum.get('reduivy__Enrollment_Status__c'));
        }

        Test.stopTest();
        
    }

    @IsTest
    static void testMatchByLetterAbsent(){
        
        Test.startTest();
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            reduivy__Study_Grade_Setting__c sgs = [SELECT Id FROM reduivy__Study_Grade_Setting__c WHERE reduivy__Sample_Record_Code__c = 'PERCENTAGE_SCORE'];

            Map<Id, List<reduivy__Study_Grading_Scheme__c>> sgsScheme = SGD_Helper.getStudyGradingSchemes(new Set<Id>{sgs.Id}, false);

            Map<String, Object> matchByNum = SGD_Helper.matchGradingScheme(null, 'A', sgsScheme.get(sgs.Id), IEN_Helper.ATTENDANCE_REQUIREMENT_MET_NO);
            System.Assert.isTrue(matchByNum != null, 'There should be 1 match');
            System.Assert.areEqual('FA', (String) matchByNum.get('reduivy__Letter_Grade__c'));
            System.Assert.areEqual(null, (Decimal) matchByNum.get('reduivy__Numerical_Grade__c'));
            System.Assert.areEqual(0, (Decimal) matchByNum.get('reduivy__Grade_Points__c'));
            System.Assert.areEqual('Fail', (String) matchByNum.get('reduivy__Grade_Result__c'));
            System.Assert.areEqual('No', (String) matchByNum.get('reduivy__Exclude_Credits_Earned__c'));
            System.Assert.areEqual('No', (String) matchByNum.get('reduivy__Exclude_GPA_Calculation__c'));
            System.Assert.areEqual('Completed Fail', (String) matchByNum.get('reduivy__Enrollment_Status__c'));
        }

        Test.stopTest();
        
    }

    @IsTest
    static void testMatchByLetterNegative(){
        
        Test.startTest();
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            reduivy__Study_Grade_Setting__c sgs = [SELECT Id FROM reduivy__Study_Grade_Setting__c WHERE reduivy__Sample_Record_Code__c = 'PERCENTAGE_SCORE'];

            Map<Id, List<reduivy__Study_Grading_Scheme__c>> sgsScheme = SGD_Helper.getStudyGradingSchemes(new Set<Id>{sgs.Id}, false);

            Map<String, Object> matchByNum = SGD_Helper.matchGradingScheme(null, 'Z', sgsScheme.get(sgs.Id), IEN_Helper.ATTENDANCE_REQUIREMENT_MET_YES);
            System.Assert.isTrue(matchByNum == null, 'There should be 0 match');
        }

        Test.stopTest();
        
    }
}