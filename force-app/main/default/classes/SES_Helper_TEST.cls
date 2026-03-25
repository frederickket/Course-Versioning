/**
 * @author      WDCi (Lean)
 * @date        Mar 2025
 * @group       Test
 * @description Test class for SES_Helper
 * @changehistory
 * 
 */
@isTest
public inherited sharing class SES_Helper_TEST {
    
    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
    
    @testSetup
    static void setupTestData() {
        testFactory.setupDefaultSettings();
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        System.runAs(ADMIN_USER) {
            Test.startTest();

            testFactory.initMasterData(null);
            testFactory.initOfferingData(null);
            testFactory.initStudentData(null, false);
            
            Id eduInstId = [SELECT Id FROM Account WHERE reduivy__Sample_Record_Code__c = 'RIOUNI' LIMIT 1].Id;
            Id studyProgramId = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = 'BACBIS' LIMIT 1].Id;
            Id studyUnitId = [SELECT Id FROM reduivy__Study_Unit__c WHERE reduivy__Sample_Record_Code__c = 'BUS101' LIMIT 1].Id;
            Id ipeId = [SELECT Id FROM reduivy__Individual_Program_Enrollment__c ORDER BY Name LIMIT 1].Id;
            
            List<reduivy__Study_Enrollment_Setting__c> sesList = new List<reduivy__Study_Enrollment_Setting__c>{
                REDU_TestData_UTIL.newStudyEnrollmentSetting('SES Inst', SES_Helper.TYPE_UNIT_MAX_ATTEMPT, eduInstId, null, null, null, 3, SES_Helper.ACTION_BLOCK),
                REDU_TestData_UTIL.newStudyEnrollmentSetting('SES Program', SES_Helper.TYPE_UNIT_MAX_ATTEMPT, eduInstId, studyProgramId, null, null, 3, SES_Helper.ACTION_BLOCK),
                REDU_TestData_UTIL.newStudyEnrollmentSetting('SES Unit', SES_Helper.TYPE_UNIT_MAX_ATTEMPT, eduInstId, null, studyUnitId, null, 3, SES_Helper.ACTION_BLOCK),
                REDU_TestData_UTIL.newStudyEnrollmentSetting('SES Program Unit', SES_Helper.TYPE_UNIT_MAX_ATTEMPT, eduInstId, studyProgramId, studyUnitId, null, 3, SES_Helper.ACTION_BLOCK),
                REDU_TestData_UTIL.newStudyEnrollmentSetting('SES IPE', SES_Helper.TYPE_UNIT_MAX_ATTEMPT, null, null, null, ipeId, 3, SES_Helper.ACTION_BLOCK),
                REDU_TestData_UTIL.newStudyEnrollmentSetting('SES IPE Unit', SES_Helper.TYPE_UNIT_MAX_ATTEMPT, null, null, studyUnitId, ipeId, 3, SES_Helper.ACTION_BLOCK)
            };
            insert sesList;
            
            Test.stopTest();
        }
    }

    /**
     * @description Test object helper method
     */
    @IsTest
    static void testObjectHelper(){
        
        Test.startTest();
        
        System.Assert.areEqual(SObjectType.reduivy__Study_Enrollment_Setting__c.getLabel(), SES_Helper.getObjectLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Enrollment_Setting__c.getLabelPlural(), SES_Helper.getObjectPluralLabel());
        System.Assert.areEqual(SObjectType.reduivy__Study_Enrollment_Setting__c.getName(), SES_Helper.getApiName());

        Test.stopTest();
        
    }

    @isTest
    static void testGetStudyEnrollmentSettings() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            Id eduInstId = [SELECT Id FROM Account WHERE reduivy__Sample_Record_Code__c = 'RIOUNI' LIMIT 1].Id;
            Id studyProgramId = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = 'BACBIS' LIMIT 1].Id;
            Id studyUnitId = [SELECT Id FROM reduivy__Study_Unit__c WHERE reduivy__Sample_Record_Code__c = 'BUS101' LIMIT 1].Id;
            Id ipeId = [SELECT Id FROM reduivy__Individual_Program_Enrollment__c ORDER BY Name LIMIT 1].Id;
            
            Set<Id> eduInstIds = new Set<Id>{ eduInstId };
            Set<Id> spgIds = new Set<Id>{ studyProgramId };
            Set<Id> sunIds = new Set<Id>{ studyUnitId };
            Set<Id> ipeIds = new Set<Id>{ ipeId };
            
            Map<String, reduivy__Study_Enrollment_Setting__c> sesMapAll = SES_Helper.getStudyEnrollmentSettings(
                SES_Helper.TYPE_UNIT_MAX_ATTEMPT, eduInstIds, spgIds, sunIds, ipeIds);
            
            System.assert(sesMapAll.size() == 6, 'Expected 6 settings but found ' + sesMapAll.size());

            Map<String, reduivy__Study_Enrollment_Setting__c> sesMapEduInst = SES_Helper.getStudyEnrollmentSettings(
                SES_Helper.TYPE_UNIT_MAX_ATTEMPT, eduInstIds, null, null, null);
            
            System.assert(sesMapEduInst.size() == 4, 'Expected 4 settings but found ' + sesMapEduInst.size());
            
            Map<String, reduivy__Study_Enrollment_Setting__c> sesMapSun = SES_Helper.getStudyEnrollmentSettings(
                SES_Helper.TYPE_UNIT_MAX_ATTEMPT, eduInstIds, null, sunIds, null);
            
            System.assert(sesMapSun.size() == 5, 'Expected 5 settings but found ' + sesMapSun.size());

            Map<String, reduivy__Study_Enrollment_Setting__c> sesMapSpg = SES_Helper.getStudyEnrollmentSettings(
                SES_Helper.TYPE_UNIT_MAX_ATTEMPT, eduInstIds, spgIds, null, null);
            
            System.assert(sesMapSpg.size() == 4, 'Expected 4 settings but found ' + sesMapSpg.size());

            Map<String, reduivy__Study_Enrollment_Setting__c> sesMapIpe = SES_Helper.getStudyEnrollmentSettings(
                SES_Helper.TYPE_UNIT_MAX_ATTEMPT, null, null, null, ipeIds);
            
            System.assert(sesMapIpe.size() == 2, 'Expected 2 settings but found ' + sesMapIpe.size());

            Test.stopTest();
        }
    }
    
    @isTest
    static void testEmptyInput() {
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        System.runAs(ADMIN_USER) {
            Test.startTest();
            
            Map<String, reduivy__Study_Enrollment_Setting__c> sesMap = SES_Helper.getStudyEnrollmentSettings(
                SES_Helper.TYPE_UNIT_MAX_ATTEMPT, new Set<Id>(), new Set<Id>(), new Set<Id>(), new Set<Id>());
            
            Test.stopTest();
            
            System.assert(sesMap.size() == 6, 'Expected 6 settings but found ' + sesMap.size());
        }
    }
    
    @isTest
    static void testGenerateIdentifier() {
        Test.startTest();
        String key = SES_Helper.generateIdentifier(new List<String>{'Edu1', 'Prog1', 'Unit1'});
        Test.stopTest();
        System.assertEquals('Edu1_Prog1_Unit1', key, 'Unexpected identifier format');
    }
}