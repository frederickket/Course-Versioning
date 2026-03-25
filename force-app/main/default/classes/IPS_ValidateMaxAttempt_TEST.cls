/**
 * @author      WDCi (Lean)
 * @date        Mar 2025
 * @group       Test
 * @description Test class for IPS_ValidateMaxAttempt_EXE
 * @changehistory
 * ISS-002231 08-04-2025 Lean - Max attempt configuration and validation
 * ISS-002447 13-05-2025 Lean - Max attempt indication
 */

@isTest
public with sharing class IPS_ValidateMaxAttempt_TEST {
    
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

            testFactory.initMasterData(SPS_Helper.getApiName());
            testFactory.initOfferingData(SOF_Helper.getApiName());
            testFactory.initStudentData(IPR_Helper.getApiName(), true);

            Test.stopTest();
        }
    }

    /*=========================== TEST for Admin ===============================*/
    /**
     * @description Test as admin with educational institution study enrollment settting with block action
     */
    @isTest
    static void testSES_InstWithBlockAsAdmin() {
        testSESCombination(testFactory.getReduAdminUser(), 'SES Inst', 1, SES_Helper.ACTION_BLOCK, true, false, false, false, false, false, true);
    }
    
    /**
     * @description Test as admin with educational institution + study program study enrollment settting with block action
     */
    @isTest
    static void testSES_ProgramWithBlockAsAdmin() {
        testSESCombination(testFactory.getReduAdminUser(), 'SES Program', 1, SES_Helper.ACTION_BLOCK, true, true, false, false, false, false, true);
    }
    
    /**
     * @description Test as admin with educational institution + study program + study unit study enrollment settting with block action
     */
    @isTest
    static void testSES_UnitWithBlockAsAdmin() {
        testSESCombination(testFactory.getReduAdminUser(), 'SES Unit', 1, SES_Helper.ACTION_BLOCK, true, true, true, false, false, false, true);
    }
    
    /**
     * @description Test as admin with educational institution + study program + study program unit study enrollment settting with block action
     */
    @isTest
    static void testSES_Program_UnitWithBlockAsAdmin() {
        testSESCombination(testFactory.getReduAdminUser(), 'SES Program Unit', 1, SES_Helper.ACTION_BLOCK, true, true, true, true, false, false, true);
    }
    
    /**
     * @description Test as admin with educational institution + study program + study program unit study + ipe enrollment settting with block action
     */
    @isTest
    static void testSES_IPEWithBlockAsAdmin() {
        testSESCombination(testFactory.getReduAdminUser(), 'SES IPE', 1, SES_Helper.ACTION_BLOCK, true, true, true, true, true, false, true);
    }
    
    /**
     * @description Test as admin with educational institution + study program + study program unit study + ipe + ipe unit enrollment settting with block action
     */
    @isTest
    static void testSES_IPE_UnitWithBlockAsAdmin() {
        testSESCombination(testFactory.getReduAdminUser(), 'SES IPE Unit', 1, SES_Helper.ACTION_BLOCK, true, true, true, true, true, true, true);
    }

    /**
     * @description Test as admin with educational institution study enrollment settting with allow action, exceeded limit and deletion of individual enrollment to rest the attempt limit status
     */
    @isTest
    static void testSES_ResetStatusAsAdmin() {
        testSESCombination(testFactory.getReduAdminUser(), 'SES Inst', 7, SES_Helper.ACTION_ALLOW, true, false, false, false, false, false, true);

        System.runAs(testFactory.getReduAdminUser()) {
            List<reduivy__Individual_Enrollment__c> ienList = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE RecordTypeId =: IEN_Helper.getStudentRecordTypeId()];
            for (reduivy__Individual_Enrollment__c ien : ienList) {
                ien.reduivy__Enrollment_Status__c = IEN_Helper.getOpenStatuses().get(0);
            }

            REDU_Database_UTIL.doUpdate(ienList);
            
            Boolean foundIpsu = false;
            for (reduivy__Individual_Plan_Structure__c ipsu : [SELECT Id,
                reduivy__Attempt_Limit_Status__c
                FROM reduivy__Individual_Plan_Structure__c
                WHERE RecordTypeId =: IPS_Helper.getUnitRecordTypeId()
            ]) {
                System.Assert.areEqual(null, ipsu.reduivy__Attempt_Limit_Status__c);
                foundIpsu = true;
            }

            System.Assert.isTrue(foundIpsu, 'No ips unit found for assertion.');
        }
    }

    /**
     * @description Test as admin with educational institution study enrollment settting with block action
     */
    @isTest
    static void testNegative_SES_InstWithBlockAsAdmin() {
        testSESCombination(testFactory.getReduAdminUser(), 'SES Inst', 7, SES_Helper.ACTION_BLOCK, true, false, false, false, false, false, false);
    }
    
    /**
     * @description Test as admin with educational institution + study program study enrollment settting with block action
     */
    @isTest
    static void testNegative_SES_ProgramWithBlockAsAdmin() {
        testSESCombination(testFactory.getReduAdminUser(), 'SES Program', 6, SES_Helper.ACTION_BLOCK, true, true, false, false, false, false, false);
    }
    
    /**
     * @description Test as admin with educational institution + study program + study unit study enrollment settting with block action
     */
    @isTest
    static void testNegative_SES_UnitWithBlockAsAdmin() {
        testSESCombination(testFactory.getReduAdminUser(), 'SES Unit', 5, SES_Helper.ACTION_BLOCK, true, true, true, false, false, false, false);
    }
    
    /**
     * @description Test as admin with educational institution + study program + study program unit study enrollment settting with block action
     */
    @isTest
    static void testNegative_SES_Program_UnitWithBlockAsAdmin() {
        testSESCombination(testFactory.getReduAdminUser(), 'SES Program Unit', 4, SES_Helper.ACTION_BLOCK, true, true, true, true, false, false, false);
    }
    
    /**
     * @description Test as admin with educational institution + study program + study program unit study + ipe enrollment settting with block action
     */
    @isTest
    static void testNegative_SES_IPEWithBlockAsAdmin() {
        testSESCombination(testFactory.getReduAdminUser(), 'SES IPE', 3, SES_Helper.ACTION_BLOCK, true, true, true, true, true, false, false);
    }
    
    /**
     * @description Test as admin with educational institution + study program + study program unit study + ipe + ipe unit enrollment settting with block action
     */
    @isTest
    static void testNegative_SES_IPE_UnitWithBlockAsAdmin() {
        testSESCombination(testFactory.getReduAdminUser(), 'SES IPE Unit', 2, SES_Helper.ACTION_BLOCK, true, true, true, true, true, true, false);
    }

    /** --- Test for allow action as Admin --- */
    /**
     * @description Test as admin with educational institution study enrollment settting with Allow action and below limit
     */
    @isTest
    static void testSES_InstWithAllowBelowLimitAsAdmin() {
        testSESCombination(testFactory.getReduAdminUser(), 'SES Inst', 1, SES_Helper.ACTION_ALLOW, true, false, false, false, false, false, true);
    }
    
    /**
     * @description Test as admin with educational institution + study program study enrollment settting with Allow action and below limit
     */
    @isTest
    static void testSES_ProgramWithAllowBelowLimitAsAdmin() {
        testSESCombination(testFactory.getReduAdminUser(), 'SES Program', 1, SES_Helper.ACTION_ALLOW, true, true, false, false, false, false, true);
    }
    
    /**
     * @description Test as admin with educational institution + study program + study unit study enrollment settting with Allow action and below limit
     */
    @isTest
    static void testSES_UnitWithAllowBelowLimitAsAdmin() {
        testSESCombination(testFactory.getReduAdminUser(), 'SES Unit', 1, SES_Helper.ACTION_ALLOW, true, true, true, false, false, false, true);
    }
    
    /**
     * @description Test as admin with educational institution + study program + study program unit study enrollment settting with Allow action and below limit
     */
    @isTest
    static void testSES_Program_UnitWithAllowBelowLimitAsAdmin() {
        testSESCombination(testFactory.getReduAdminUser(), 'SES Program Unit', 1, SES_Helper.ACTION_ALLOW, true, true, true, true, false, false, true);
    }
    
    /**
     * @description Test as admin with educational institution + study program + study program unit study + ipe enrollment settting with Allow action and below limit
     */
    @isTest
    static void testSES_IPEWithAllowBelowLimitAsAdmin() {
        testSESCombination(testFactory.getReduAdminUser(), 'SES IPE', 1, SES_Helper.ACTION_ALLOW, true, true, true, true, true, false, true);
    }
    
    /**
     * @description Test as admin with educational institution + study program + study program unit study + ipe + ipe unit enrollment settting with Allow action and below limit
     */
    @isTest
    static void testSES_IPE_UnitWithAllowBelowLimitAsAdmin() {
        testSESCombination(testFactory.getReduAdminUser(), 'SES IPE Unit', 1, SES_Helper.ACTION_ALLOW, true, true, true, true, true, true, true);
    }
    
    /**
     * @description Test as admin with educational institution study enrollment settting with Allow action and at limit
     */
    @isTest
    static void testSES_InstWithAllowAtLimitAsAdmin() {
        testSESCombination(testFactory.getReduAdminUser(), 'SES Inst', 6, SES_Helper.ACTION_ALLOW, true, false, false, false, false, false, true);
    }
    
    /**
     * @description Test as admin with educational institution + study program study enrollment settting with Allow action and at limit
     */
    @isTest
    static void testSES_ProgramWithAllowAtLimitAsAdmin() {
        testSESCombination(testFactory.getReduAdminUser(), 'SES Program', 5, SES_Helper.ACTION_ALLOW, true, true, false, false, false, false, true);
    }
    
    /**
     * @description Test as admin with educational institution + study program + study unit study enrollment settting with Allow action and at limit
     */
    @isTest
    static void testSES_UnitWithAllowAtLimitAsAdmin() {
        testSESCombination(testFactory.getReduAdminUser(), 'SES Unit', 4, SES_Helper.ACTION_ALLOW, true, true, true, false, false, false, true);
    }
    
    /**
     * @description Test as admin with educational institution + study program + study program unit study enrollment settting with Allow action and at limit
     */
    @isTest
    static void testSES_Program_UnitWithAllowAtLimitAsAdmin() {
        testSESCombination(testFactory.getReduAdminUser(), 'SES Program Unit', 3, SES_Helper.ACTION_ALLOW, true, true, true, true, false, false, true);
    }
    
    /**
     * @description Test as admin with educational institution + study program + study program unit study + ipe enrollment settting with Allow action and at limit
     */
    @isTest
    static void testSES_IPEWithAllowAtLimitAsAdmin() {
        testSESCombination(testFactory.getReduAdminUser(), 'SES IPE', 2, SES_Helper.ACTION_ALLOW, true, true, true, true, true, false, true);
    }
    
    /**
     * @description Test as admin with educational institution + study program + study program unit study + ipe + ipe unit enrollment settting with Allow action and at limit
     */
    @isTest
    static void testSES_IPE_UnitWithAllowAtLimitAsAdmin() {
        testSESCombination(testFactory.getReduAdminUser(), 'SES IPE Unit', 1, SES_Helper.ACTION_ALLOW, true, true, true, true, true, true, true);
    }
    
    /**
     * @description Test as admin with educational institution study enrollment settting with Allow action and exceed limit
     */
    @isTest
    static void testSES_InstWithAllowExceedLimitAsAdmin() {
        testSESCombination(testFactory.getReduAdminUser(), 'SES Inst', 7, SES_Helper.ACTION_ALLOW, true, false, false, false, false, false, true);
    }
    
    /**
     * @description Test as admin with educational institution + study program study enrollment settting with Allow action and exceed limit
     */
    @isTest
    static void testSES_ProgramWithAllowExceedLimitAsAdmin() {
        testSESCombination(testFactory.getReduAdminUser(), 'SES Program', 6, SES_Helper.ACTION_ALLOW, true, true, false, false, false, false, true);
    }
    
    /**
     * @description Test as admin with educational institution + study program + study unit study enrollment settting with Allow action and exceed limit
     */
    @isTest
    static void testSES_UnitWithAllowExceedLimitAsAdmin() {
        testSESCombination(testFactory.getReduAdminUser(), 'SES Unit', 5, SES_Helper.ACTION_ALLOW, true, true, true, false, false, false, true);
    }
    
    /**
     * @description Test as admin with educational institution + study program + study program unit study enrollment settting with Allow action and exceed limit
     */
    @isTest
    static void testSES_Program_UnitWithAllowExceedLimitAsAdmin() {
        testSESCombination(testFactory.getReduAdminUser(), 'SES Program Unit', 4, SES_Helper.ACTION_ALLOW, true, true, true, true, false, false, true);
    }
    
    /**
     * @description Test as admin with educational institution + study program + study program unit study + ipe enrollment settting with Allow action and exceed limit
     */
    @isTest
    static void testSES_IPEWithAllowExceedLimitAsAdmin() {
        testSESCombination(testFactory.getReduAdminUser(), 'SES IPE', 3, SES_Helper.ACTION_ALLOW, true, true, true, true, true, false, true);
    }
    
    /**
     * @description Test as admin with educational institution + study program + study program unit study + ipe + ipe unit enrollment settting with Allow action and exceed limit
     */
    @isTest
    static void testSES_IPE_UnitWithAllowExceedLimitAsAdmin() {
        testSESCombination(testFactory.getReduAdminUser(), 'SES IPE Unit', 2, SES_Helper.ACTION_ALLOW, true, true, true, true, true, true, true);
    }

    /*=========================== TEST for Faculty ===============================*/
    /**
     * @description Test as faculty with educational institution study enrollment settting with block action
     */
    @isTest
    static void testSES_InstWithBlockAsFaculty() {
        testSESCombination(testFactory.getReduFacultyUser(), 'SES Inst', 1, SES_Helper.ACTION_BLOCK, true, false, false, false, false, false, true);
    }
    
    /**
     * @description Test as Faculty with educational institution + study program study enrollment settting with block action
     */
    @isTest
    static void testSES_ProgramWithBlockAsFaculty() {
        testSESCombination(testFactory.getReduFacultyUser(), 'SES Program', 1, SES_Helper.ACTION_BLOCK, true, true, false, false, false, false, true);
    }
    
    /**
     * @description Test as Faculty with educational institution + study program + study unit study enrollment settting with block action
     */
    @isTest
    static void testSES_UnitWithBlockAsFaculty() {
        testSESCombination(testFactory.getReduFacultyUser(), 'SES Unit', 1, SES_Helper.ACTION_BLOCK, true, true, true, false, false, false, true);
    }
    
    /**
     * @description Test as Faculty with educational institution + study program + study program unit study enrollment settting with block action
     */
    @isTest
    static void testSES_Program_UnitWithBlockAsFaculty() {
        testSESCombination(testFactory.getReduFacultyUser(), 'SES Program Unit', 1, SES_Helper.ACTION_BLOCK, true, true, true, true, false, false, true);
    }
    
    /**
     * @description Test as Faculty with educational institution + study program + study program unit study + ipe enrollment settting with block action
     */
    @isTest
    static void testSES_IPEWithBlockAsFaculty() {
        testSESCombination(testFactory.getReduFacultyUser(), 'SES IPE', 1, SES_Helper.ACTION_BLOCK, true, true, true, true, true, false, true);
    }
    
    /**
     * @description Test as Faculty with educational institution + study program + study program unit study + ipe + ipe unit enrollment settting with block action
     */
    @isTest
    static void testSES_IPE_UnitWithBlockAsFaculty() {
        testSESCombination(testFactory.getReduFacultyUser(), 'SES IPE Unit', 1, SES_Helper.ACTION_BLOCK, true, true, true, true, true, true, true);
    }

    /**
     * @description Test as faculty with educational institution study enrollment settting with allow action, exceeded limit and deletion of individual enrollment to rest the attempt limit status
     */
    @isTest
    static void testSES_ResetStatusAsFaculty() {
        testSESCombination(testFactory.getReduFacultyUser(), 'SES Inst', 7, SES_Helper.ACTION_ALLOW, true, false, false, false, false, false, true);

        System.runAs(testFactory.getReduFacultyUser()) {
            List<reduivy__Individual_Enrollment__c> ienList = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE RecordTypeId =: IEN_Helper.getStudentRecordTypeId()];
            for (reduivy__Individual_Enrollment__c ien : ienList) {
                ien.reduivy__Enrollment_Status__c = IEN_Helper.getOpenStatuses().get(0);
            }

            REDU_Database_UTIL.doUpdate(ienList);

            Boolean foundIpsu = false;
            for (reduivy__Individual_Plan_Structure__c ipsu : [SELECT Id,
                reduivy__Attempt_Limit_Status__c
                FROM reduivy__Individual_Plan_Structure__c
                WHERE RecordTypeId =: IPS_Helper.getUnitRecordTypeId()
            ]) {
                System.Assert.areEqual(null, ipsu.reduivy__Attempt_Limit_Status__c);
                foundIpsu = true;
            }

            System.Assert.isTrue(foundIpsu, 'No ips unit found for assertion.');
        }
    }

    /**
     * @description Test as Faculty with educational institution study enrollment settting with block action
     */
    @isTest
    static void testNegative_SES_InstWithBlockAsFaculty() {
        testSESCombination(testFactory.getReduFacultyUser(), 'SES Inst', 7, SES_Helper.ACTION_BLOCK, true, false, false, false, false, false, false);
    }
    
    /**
     * @description Test as Faculty with educational institution + study program study enrollment settting with block action
     */
    @isTest
    static void testNegative_SES_ProgramWithBlockAsFaculty() {
        testSESCombination(testFactory.getReduFacultyUser(), 'SES Program', 6, SES_Helper.ACTION_BLOCK, true, true, false, false, false, false, false);
    }
    
    /**
     * @description Test as Faculty with educational institution + study program + study unit study enrollment settting with block action
     */
    @isTest
    static void testNegative_SES_UnitWithBlockAsFaculty() {
        testSESCombination(testFactory.getReduFacultyUser(), 'SES Unit', 5, SES_Helper.ACTION_BLOCK, true, true, true, false, false, false, false);
    }
    
    /**
     * @description Test as Faculty with educational institution + study program + study program unit study enrollment settting with block action
     */
    @isTest
    static void testNegative_SES_Program_UnitWithBlockAsFaculty() {
        testSESCombination(testFactory.getReduFacultyUser(), 'SES Program Unit', 4, SES_Helper.ACTION_BLOCK, true, true, true, true, false, false, false);
    }
    
    /**
     * @description Test as Faculty with educational institution + study program + study program unit study + ipe enrollment settting with block action
     */
    @isTest
    static void testNegative_SES_IPEWithBlockAsFaculty() {
        testSESCombination(testFactory.getReduFacultyUser(), 'SES IPE', 3, SES_Helper.ACTION_BLOCK, true, true, true, true, true, false, false);
    }
    
    /**
     * @description Test as Faculty with educational institution + study program + study program unit study + ipe + ipe unit enrollment settting with block action
     */
    @isTest
    static void testNegative_SES_IPE_UnitWithBlockAsFaculty() {
        testSESCombination(testFactory.getReduFacultyUser(), 'SES IPE Unit', 2, SES_Helper.ACTION_BLOCK, true, true, true, true, true, true, false);
    }

    /** --- Test for allow action as Faculty --- */
    /**
     * @description Test as faculty with educational institution study enrollment settting with Allow action and below limit
     */
    @isTest
    static void testSES_InstWithAllowBelowLimitAsFaculty() {
        testSESCombination(testFactory.getReduFacultyUser(), 'SES Inst', 1, SES_Helper.ACTION_ALLOW, true, false, false, false, false, false, true);
    }
    
    /**
     * @description Test as Faculty with educational institution + study program study enrollment settting with Allow action and below limit
     */
    @isTest
    static void testSES_ProgramWithAllowBelowLimitAsFaculty() {
        testSESCombination(testFactory.getReduFacultyUser(), 'SES Program', 1, SES_Helper.ACTION_ALLOW, true, true, false, false, false, false, true);
    }
    
    /**
     * @description Test as Faculty with educational institution + study program + study unit study enrollment settting with Allow action and below limit
     */
    @isTest
    static void testSES_UnitWithAllowBelowLimitAsFaculty() {
        testSESCombination(testFactory.getReduFacultyUser(), 'SES Unit', 1, SES_Helper.ACTION_ALLOW, true, true, true, false, false, false, true);
    }
    
    /**
     * @description Test as Faculty with educational institution + study program + study program unit study enrollment settting with Allow action and below limit
     */
    @isTest
    static void testSES_Program_UnitWithAllowBelowLimitAsFaculty() {
        testSESCombination(testFactory.getReduFacultyUser(), 'SES Program Unit', 1, SES_Helper.ACTION_ALLOW, true, true, true, true, false, false, true);
    }
    
    /**
     * @description Test as Faculty with educational institution + study program + study program unit study + ipe enrollment settting with Allow action and below limit
     */
    @isTest
    static void testSES_IPEWithAllowBelowLimitAsFaculty() {
        testSESCombination(testFactory.getReduFacultyUser(), 'SES IPE', 1, SES_Helper.ACTION_ALLOW, true, true, true, true, true, false, true);
    }
    
    /**
     * @description Test as Faculty with educational institution + study program + study program unit study + ipe + ipe unit enrollment settting with Allow action and below limit
     */
    @isTest
    static void testSES_IPE_UnitWithAllowBelowLimitAsFaculty() {
        testSESCombination(testFactory.getReduFacultyUser(), 'SES IPE Unit', 1, SES_Helper.ACTION_ALLOW, true, true, true, true, true, true, true);
    }
    
    /**
     * @description Test as Faculty with educational institution study enrollment settting with Allow action and at limit
     */
    @isTest
    static void testSES_InstWithAllowAtLimitAsFaculty() {
        testSESCombination(testFactory.getReduFacultyUser(), 'SES Inst', 6, SES_Helper.ACTION_ALLOW, true, false, false, false, false, false, true);
    }
    
    /**
     * @description Test as Faculty with educational institution + study program study enrollment settting with Allow action and at limit
     */
    @isTest
    static void testSES_ProgramWithAllowAtLimitAsFaculty() {
        testSESCombination(testFactory.getReduFacultyUser(), 'SES Program', 5, SES_Helper.ACTION_ALLOW, true, true, false, false, false, false, true);
    }
    
    /**
     * @description Test as Faculty with educational institution + study program + study unit study enrollment settting with Allow action and at limit
     */
    @isTest
    static void testSES_UnitWithAllowAtLimitAsFaculty() {
        testSESCombination(testFactory.getReduFacultyUser(), 'SES Unit', 4, SES_Helper.ACTION_ALLOW, true, true, true, false, false, false, true);
    }
    
    /**
     * @description Test as Faculty with educational institution + study program + study program unit study enrollment settting with Allow action and at limit
     */
    @isTest
    static void testSES_Program_UnitWithAllowAtLimitAsFaculty() {
        testSESCombination(testFactory.getReduFacultyUser(), 'SES Program Unit', 3, SES_Helper.ACTION_ALLOW, true, true, true, true, false, false, true);
    }
    
    /**
     * @description Test as Faculty with educational institution + study program + study program unit study + ipe enrollment settting with Allow action and at limit
     */
    @isTest
    static void testSES_IPEWithAllowAtLimitAsFaculty() {
        testSESCombination(testFactory.getReduFacultyUser(), 'SES IPE', 2, SES_Helper.ACTION_ALLOW, true, true, true, true, true, false, true);
    }
    
    /**
     * @description Test as Faculty with educational institution + study program + study program unit study + ipe + ipe unit enrollment settting with Allow action and at limit
     */
    @isTest
    static void testSES_IPE_UnitWithAllowAtLimitAsFaculty() {
        testSESCombination(testFactory.getReduFacultyUser(), 'SES IPE Unit', 1, SES_Helper.ACTION_ALLOW, true, true, true, true, true, true, true);
    }
    
    /**
     * @description Test as Faculty with educational institution study enrollment settting with Allow action and exceed limit
     */
    @isTest
    static void testSES_InstWithAllowExceedLimitAsFaculty() {
        testSESCombination(testFactory.getReduFacultyUser(), 'SES Inst', 7, SES_Helper.ACTION_ALLOW, true, false, false, false, false, false, true);
    }
    
    /**
     * @description Test as Faculty with educational institution + study program study enrollment settting with Allow action and exceed limit
     */
    @isTest
    static void testSES_ProgramWithAllowExceedLimitAsFaculty() {
        testSESCombination(testFactory.getReduFacultyUser(), 'SES Program', 6, SES_Helper.ACTION_ALLOW, true, true, false, false, false, false, true);
    }
    
    /**
     * @description Test as Faculty with educational institution + study program + study unit study enrollment settting with Allow action and exceed limit
     */
    @isTest
    static void testSES_UnitWithAllowExceedLimitAsFaculty() {
        testSESCombination(testFactory.getReduFacultyUser(), 'SES Unit', 5, SES_Helper.ACTION_ALLOW, true, true, true, false, false, false, true);
    }
    
    /**
     * @description Test as Faculty with educational institution + study program + study program unit study enrollment settting with Allow action and exceed limit
     */
    @isTest
    static void testSES_Program_UnitWithAllowExceedLimitAsFaculty() {
        testSESCombination(testFactory.getReduFacultyUser(), 'SES Program Unit', 4, SES_Helper.ACTION_ALLOW, true, true, true, true, false, false, true);
    }
    
    /**
     * @description Test as Faculty with educational institution + study program + study program unit study + ipe enrollment settting with Allow action and exceed limit
     */
    @isTest
    static void testSES_IPEWithAllowExceedLimitAsFaculty() {
        testSESCombination(testFactory.getReduFacultyUser(), 'SES IPE', 3, SES_Helper.ACTION_ALLOW, true, true, true, true, true, false, true);
    }
    
    /**
     * @description Test as Faculty with educational institution + study program + study program unit study + ipe + ipe unit enrollment settting with Allow action and exceed limit
     */
    @isTest
    static void testSES_IPE_UnitWithAllowExceedLimitAsFaculty() {
        testSESCombination(testFactory.getReduFacultyUser(), 'SES IPE Unit', 2, SES_Helper.ACTION_ALLOW, true, true, true, true, true, true, true);
    }

    /*=========================== TEST for Student ===============================*/
    /**
     * @description Test as Student with educational institution study enrollment settting with block action
     */
    @isTest
    static void testSES_InstWithBlockAsStudent() {
        testSESCombination(testFactory.getStudentUser(), 'SES Inst', 1, SES_Helper.ACTION_BLOCK, true, false, false, false, false, false, true);
    }
    
    /**
     * @description Test as Student with educational institution + study program study enrollment settting with block action
     */
    @isTest
    static void testSES_ProgramWithBlockAsStudent() {
        testSESCombination(testFactory.getStudentUser(), 'SES Program', 1, SES_Helper.ACTION_BLOCK, true, true, false, false, false, false, true);
    }
    
    /**
     * @description Test as Student with educational institution + study program + study unit study enrollment settting with block action
     */
    @isTest
    static void testSES_UnitWithBlockAsStudent() {
        testSESCombination(testFactory.getStudentUser(), 'SES Unit', 1, SES_Helper.ACTION_BLOCK, true, true, true, false, false, false, true);
    }
    
    /**
     * @description Test as Student with educational institution + study program + study program unit study enrollment settting with block action
     */
    @isTest
    static void testSES_Program_UnitWithBlockAsStudent() {
        testSESCombination(testFactory.getStudentUser(), 'SES Program Unit', 1, SES_Helper.ACTION_BLOCK, true, true, true, true, false, false, true);
    }
    
    /**
     * @description Test as Student with educational institution + study program + study program unit study + ipe enrollment settting with block action
     */
    @isTest
    static void testSES_IPEWithBlockAsStudent() {
        testSESCombination(testFactory.getStudentUser(), 'SES IPE', 1, SES_Helper.ACTION_BLOCK, true, true, true, true, true, false, true);
    }
    
    /**
     * @description Test as Student with educational institution + study program + study program unit study + ipe + ipe unit enrollment settting with block action
     */
    @isTest
    static void testSES_IPE_UnitWithBlockAsStudent() {
        testSESCombination(testFactory.getStudentUser(), 'SES IPE Unit', 1, SES_Helper.ACTION_BLOCK, true, true, true, true, true, true, true);
    }

    /**
     * @description Test as student with educational institution study enrollment settting with allow action, exceeded limit and deletion of individual enrollment to rest the attempt limit status
     */
    @isTest
    static void testSES_ResetStatusAsStudent() {
        User studentUser = testFactory.getStudentUser();

        testSESCombination(studentUser, 'SES Inst', 7, SES_Helper.ACTION_ALLOW, true, false, false, false, false, false, true);

        System.runAs(studentUser) {
            List<reduivy__Individual_Enrollment__c> ienList = [SELECT Id FROM reduivy__Individual_Enrollment__c WHERE RecordTypeId =: IEN_Helper.getStudentRecordTypeId()];
            for (reduivy__Individual_Enrollment__c ien : ienList) {
                ien.reduivy__Enrollment_Status__c = IEN_Helper.getOpenStatuses().get(0);
            }

            REDU_Database_UTIL.doUpdate(ienList);

            Boolean foundIpsu = false;
            for (reduivy__Individual_Plan_Structure__c ipsu : [SELECT Id,
                reduivy__Attempt_Limit_Status__c
                FROM reduivy__Individual_Plan_Structure__c
                WHERE RecordTypeId =: IPS_Helper.getUnitRecordTypeId()
            ]) {
                System.Assert.areEqual(null, ipsu.reduivy__Attempt_Limit_Status__c);
                foundIpsu = true;
            }

            System.Assert.isTrue(foundIpsu, 'No ips unit found for assertion.');
        }
    }

    /**
     * @description Test as Student with educational institution study enrollment settting with block action
     */
    @isTest
    static void testNegative_SES_InstWithBlockAsStudent() {
        testSESCombination(testFactory.getStudentUser(), 'SES Inst', 7, SES_Helper.ACTION_BLOCK, true, false, false, false, false, false, false);
    }
    
    /**
     * @description Test as Student with educational institution + study program study enrollment settting with block action
     */
    @isTest
    static void testNegative_SES_ProgramWithBlockAsStudent() {
        testSESCombination(testFactory.getStudentUser(), 'SES Program', 6, SES_Helper.ACTION_BLOCK, true, true, false, false, false, false, false);
    }
    
    /**
     * @description Test as Student with educational institution + study program + study unit study enrollment settting with block action
     */
    @isTest
    static void testNegative_SES_UnitWithBlockAsStudent() {
        testSESCombination(testFactory.getStudentUser(), 'SES Unit', 5, SES_Helper.ACTION_BLOCK, true, true, true, false, false, false, false);
    }
    
    /**
     * @description Test as Student with educational institution + study program + study program unit study enrollment settting with block action
     */
    @isTest
    static void testNegative_SES_Program_UnitWithBlockAsStudent() {
        testSESCombination(testFactory.getStudentUser(), 'SES Program Unit', 4, SES_Helper.ACTION_BLOCK, true, true, true, true, false, false, false);
    }
    
    /**
     * @description Test as Student with educational institution + study program + study program unit study + ipe enrollment settting with block action
     */
    @isTest
    static void testNegative_SES_IPEWithBlockAsStudent() {
        testSESCombination(testFactory.getStudentUser(), 'SES IPE', 3, SES_Helper.ACTION_BLOCK, true, true, true, true, true, false, false);
    }
    
    /**
     * @description Test as Student with educational institution + study program + study program unit study + ipe + ipe unit enrollment settting with block action
     */
    @isTest
    static void testNegative_SES_IPE_UnitWithBlockAsStudent() {
        testSESCombination(testFactory.getStudentUser(), 'SES IPE Unit', 2, SES_Helper.ACTION_BLOCK, true, true, true, true, true, true, false);
    }

    /** --- Test for allow action as Student --- */
    /**
     * @description Test as Student with educational institution study enrollment settting with Allow action and below limit
     */
    @isTest
    static void testSES_InstWithAllowBelowLimitAsStudent() {
        testSESCombination(testFactory.getStudentUser(), 'SES Inst', 1, SES_Helper.ACTION_ALLOW, true, false, false, false, false, false, true);
    }
    
    /**
     * @description Test as Student with educational institution + study program study enrollment settting with Allow action and below limit
     */
    @isTest
    static void testSES_ProgramWithAllowBelowLimitAsStudent() {
        testSESCombination(testFactory.getStudentUser(), 'SES Program', 1, SES_Helper.ACTION_ALLOW, true, true, false, false, false, false, true);
    }
    
    /**
     * @description Test as Student with educational institution + study program + study unit study enrollment settting with Allow action and below limit
     */
    @isTest
    static void testSES_UnitWithAllowBelowLimitAsStudent() {
        testSESCombination(testFactory.getStudentUser(), 'SES Unit', 1, SES_Helper.ACTION_ALLOW, true, true, true, false, false, false, true);
    }
    
    /**
     * @description Test as Student with educational institution + study program + study program unit study enrollment settting with Allow action and below limit
     */
    @isTest
    static void testSES_Program_UnitWithAllowBelowLimitAsStudent() {
        testSESCombination(testFactory.getStudentUser(), 'SES Program Unit', 1, SES_Helper.ACTION_ALLOW, true, true, true, true, false, false, true);
    }
    
    /**
     * @description Test as Student with educational institution + study program + study program unit study + ipe enrollment settting with Allow action and below limit
     */
    @isTest
    static void testSES_IPEWithAllowBelowLimitAsStudent() {
        testSESCombination(testFactory.getStudentUser(), 'SES IPE', 1, SES_Helper.ACTION_ALLOW, true, true, true, true, true, false, true);
    }
    
    /**
     * @description Test as Student with educational institution + study program + study program unit study + ipe + ipe unit enrollment settting with Allow action and below limit
     */
    @isTest
    static void testSES_IPE_UnitWithAllowBelowLimitAsStudent() {
        testSESCombination(testFactory.getStudentUser(), 'SES IPE Unit', 1, SES_Helper.ACTION_ALLOW, true, true, true, true, true, true, true);
    }
    
    /**
     * @description Test as Student with educational institution study enrollment settting with Allow action and at limit
     */
    @isTest
    static void testSES_InstWithAllowAtLimitAsStudent() {
        testSESCombination(testFactory.getStudentUser(), 'SES Inst', 6, SES_Helper.ACTION_ALLOW, true, false, false, false, false, false, true);
    }
    
    /**
     * @description Test as Student with educational institution + study program study enrollment settting with Allow action and at limit
     */
    @isTest
    static void testSES_ProgramWithAllowAtLimitAsStudent() {
        testSESCombination(testFactory.getStudentUser(), 'SES Program', 5, SES_Helper.ACTION_ALLOW, true, true, false, false, false, false, true);
    }
    
    /**
     * @description Test as Student with educational institution + study program + study unit study enrollment settting with Allow action and at limit
     */
    @isTest
    static void testSES_UnitWithAllowAtLimitAsStudent() {
        testSESCombination(testFactory.getStudentUser(), 'SES Unit', 4, SES_Helper.ACTION_ALLOW, true, true, true, false, false, false, true);
    }
    
    /**
     * @description Test as Student with educational institution + study program + study program unit study enrollment settting with Allow action and at limit
     */
    @isTest
    static void testSES_Program_UnitWithAllowAtLimitAsStudent() {
        testSESCombination(testFactory.getStudentUser(), 'SES Program Unit', 3, SES_Helper.ACTION_ALLOW, true, true, true, true, false, false, true);
    }
    
    /**
     * @description Test as Student with educational institution + study program + study program unit study + ipe enrollment settting with Allow action and at limit
     */
    @isTest
    static void testSES_IPEWithAllowAtLimitAsStudent() {
        testSESCombination(testFactory.getStudentUser(), 'SES IPE', 2, SES_Helper.ACTION_ALLOW, true, true, true, true, true, false, true);
    }
    
    /**
     * @description Test as Student with educational institution + study program + study program unit study + ipe + ipe unit enrollment settting with Allow action and at limit
     */
    @isTest
    static void testSES_IPE_UnitWithAllowAtLimitAsStudent() {
        testSESCombination(testFactory.getStudentUser(), 'SES IPE Unit', 1, SES_Helper.ACTION_ALLOW, true, true, true, true, true, true, true);
    }
    
    /**
     * @description Test as Student with educational institution study enrollment settting with Allow action and exceed limit
     */
    @isTest
    static void testSES_InstWithAllowExceedLimitAsStudent() {
        testSESCombination(testFactory.getStudentUser(), 'SES Inst', 7, SES_Helper.ACTION_ALLOW, true, false, false, false, false, false, true);
    }
    
    /**
     * @description Test as Student with educational institution + study program study enrollment settting with Allow action and exceed limit
     */
    @isTest
    static void testSES_ProgramWithAllowExceedLimitAsStudent() {
        testSESCombination(testFactory.getStudentUser(), 'SES Program', 6, SES_Helper.ACTION_ALLOW, true, true, false, false, false, false, true);
    }
    
    /**
     * @description Test as Student with educational institution + study program + study unit study enrollment settting with Allow action and exceed limit
     */
    @isTest
    static void testSES_UnitWithAllowExceedLimitAsStudent() {
        testSESCombination(testFactory.getStudentUser(), 'SES Unit', 5, SES_Helper.ACTION_ALLOW, true, true, true, false, false, false, true);
    }
    
    /**
     * @description Test as Student with educational institution + study program + study program unit study enrollment settting with Allow action and exceed limit
     */
    @isTest
    static void testSES_Program_UnitWithAllowExceedLimitAsStudent() {
        testSESCombination(testFactory.getStudentUser(), 'SES Program Unit', 4, SES_Helper.ACTION_ALLOW, true, true, true, true, false, false, true);
    }
    
    /**
     * @description Test as Student with educational institution + study program + study program unit study + ipe enrollment settting with Allow action and exceed limit
     */
    @isTest
    static void testSES_IPEWithAllowExceedLimitAsStudent() {
        testSESCombination(testFactory.getStudentUser(), 'SES IPE', 3, SES_Helper.ACTION_ALLOW, true, true, true, true, true, false, true);
    }
    
    /**
     * @description Test as Student with educational institution + study program + study program unit study + ipe + ipe unit enrollment settting with Allow action and exceed limit
     */
    @isTest
    static void testSES_IPE_UnitWithAllowExceedLimitAsStudent() {
        testSESCombination(testFactory.getStudentUser(), 'SES IPE Unit', 2, SES_Helper.ACTION_ALLOW, true, true, true, true, true, true, true);
    }

    /**
     * @description Shared test method to setup data and test the validation
     */
    private static void testSESCombination(User runningUser, String testName, Integer testLimit, String sesAction, Boolean includeInst, Boolean includeProgram, Boolean includeUnit, Boolean includeProgramUnit, Boolean includeIPE, Boolean includeIPEUnit, Boolean expectedResult) {
        User ADMIN_USER = testFactory.getReduAdminUser();

        Id eduInstId = [SELECT Id FROM Account WHERE reduivy__Sample_Record_Code__c = 'RIOUNI' LIMIT 1].Id;
        Id studyProgramId = [SELECT Id FROM reduivy__Study_Program__c WHERE reduivy__Sample_Record_Code__c = 'BACBIS' LIMIT 1].Id;
        Id studyUnitId = [SELECT Id FROM reduivy__Study_Unit__c WHERE reduivy__Sample_Record_Code__c = 'BUS101' LIMIT 1].Id;
        Id studyOfferingId = [SELECT Id FROM reduivy__Study_Offering__c WHERE reduivy__Study_Unit__c =: studyUnitId AND reduivy__Academic_Term__r.reduivy__Sample_Record_Code__c =: testFactory.CYTKey LIMIT 1].Id;
        
        Integer sesLimit = 0;

        List<reduivy__Individual_Program_Enrollment__c> ipeList = new List<reduivy__Individual_Program_Enrollment__c>();
        System.runAs(runningUser) {
            for (Contact contact : [SELECT Id FROM Contact WHERE reduivy__Contact_Type__c =: CON_Helper.CONTACT_TYPE_STUDENT ORDER BY Name]) {
                ipeList.add(
                    REDU_TestData_UTIL.newMasterIndividualProgramEnrollment(
                        contact.Id,
                        contact.Id,
                        studyProgramId,
                        null,
                        null,
                        null,
                        null,
                        null,
                        null,
                        null,
                        true,
                        IPE_Helper.getInProgressStatuses().get(0),
                        null
                    )
                );
            }
        }
            
        System.runAs(ADMIN_USER) {
            REDU_Database_UTIL.doInsert(ipeList);

            if (includeInst) {
                sesLimit = 6;
                insert REDU_TestData_UTIL.newStudyEnrollmentSetting('SES Inst', SES_Helper.TYPE_UNIT_MAX_ATTEMPT, eduInstId, null, null, null, sesLimit, sesAction);
            }

            if (includeProgram) {
                sesLimit = 5;
                insert REDU_TestData_UTIL.newStudyEnrollmentSetting('SES Program', SES_Helper.TYPE_UNIT_MAX_ATTEMPT, eduInstId, studyProgramId, null, null, sesLimit, sesAction);
            }

            if (includeUnit) {
                sesLimit = 4;
                insert REDU_TestData_UTIL.newStudyEnrollmentSetting('SES Unit', SES_Helper.TYPE_UNIT_MAX_ATTEMPT, eduInstId, null, studyUnitId, null, sesLimit, sesAction);
            }

            if (includeProgramUnit) {
                sesLimit = 3;
                insert REDU_TestData_UTIL.newStudyEnrollmentSetting('SES Program Unit', SES_Helper.TYPE_UNIT_MAX_ATTEMPT, eduInstId, studyProgramId, studyUnitId, null, sesLimit, sesAction);
            }

            if (includeIPE) {
                sesLimit = 2;
                insert REDU_TestData_UTIL.newStudyEnrollmentSetting('SES IPE', SES_Helper.TYPE_UNIT_MAX_ATTEMPT, null, null, null, ipeList.get(0).Id, sesLimit, sesAction);
            }

            if (includeIPEUnit) {
                sesLimit = 1;
                insert REDU_TestData_UTIL.newStudyEnrollmentSetting('SES IPE Unit', SES_Helper.TYPE_UNIT_MAX_ATTEMPT, null, null, studyUnitId, ipeList.get(0).Id, sesLimit, sesAction);
            }
            
        }

        Test.startTest();
        System.runAs(runningUser) {
            validateMaxAttempt(testName, ipeList, studyOfferingId, testLimit, sesLimit, expectedResult);
        }

        Test.stopTest();
    }

    private static void validateMaxAttempt(String testName, List<reduivy__Individual_Program_Enrollment__c> ipeList, Id studyOfferingId, Integer testLimit, Integer sesLimit, Boolean expectedResult) {
        
        Boolean foundIpsuBeforeCheck = false;
        for (reduivy__Individual_Plan_Structure__c ipsu : [SELECT Id,
            reduivy__Attempt_Limit_Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId =: IPS_Helper.getUnitRecordTypeId()
            AND reduivy__Individual_Program_Enrollment__c IN: ipeList
        ]) {
            System.Assert.areEqual(null, ipsu.reduivy__Attempt_Limit_Status__c);
            foundIpsuBeforeCheck = true;
        }

        System.Assert.isTrue(foundIpsuBeforeCheck, 'No ips unit found for assertion before the test.');
        

        List<reduivy__Individual_Enrollment__c> ienInsertList = new List<reduivy__Individual_Enrollment__c>();

        for (reduivy__Individual_Program_Enrollment__c ipe : ipeList) {
            reduivy__Individual_Enrollment__c ien = new reduivy__Individual_Enrollment__c(
                RecordTypeId = IEN_Helper.getStudentRecordTypeId(),
                reduivy__Contact__c = ipe.reduivy__Contact__c,
                reduivy__Attempt_Number__c = testLimit,
                reduivy__Study_Offering__c = studyOfferingId,
                reduivy__Enrollment_Status__c = IEN_Helper.getInProgressStatuses().get(0)
            );

            ienInsertList.add(ien);
        }

        System.Assert.isTrue(!ienInsertList.isEmpty(), 'There is no student found for enrollment.');

        if (expectedResult) {
            try {
                REDU_Database_UTIL.doInsert(ienInsertList);

                Decimal expectedLimit = sesLimit;
                String expectedLimitStatus = IPS_Helper.ATTEMPT_LIMIT_STATUS_BELOWLIMIT;
                if (testLimit > sesLimit) {
                    expectedLimitStatus = IPS_Helper.ATTEMPT_LIMIT_STATUS_EXCEEDEDLIMIT;
                } else if (testLimit == sesLimit) {
                    expectedLimitStatus = IPS_Helper.ATTEMPT_LIMIT_STATUS_ATLIMIT;
                }

                Boolean foundIpsu = false;
                for (reduivy__Individual_Plan_Structure__c ipsu : [SELECT Id,
                    reduivy__Attempt_Limit__c,
                    reduivy__Attempt_Limit_Status__c,
                    reduivy__Individual_Program_Enrollment__c,
                    reduivy__Individual_Enrollment__c,
                    reduivy__Individual_Enrollment__r.reduivy__Attempt_Number__c
                    FROM reduivy__Individual_Plan_Structure__c
                    WHERE reduivy__Individual_Enrollment__c IN: ienInsertList
                ]) {

                    if (testName == 'SES IPE' || testName == 'SES IPE Unit') {
                        //for ipe test, only the first ipe has study enrollment setting that will cause failure
                        if (ipsu.reduivy__Individual_Program_Enrollment__c == ipeList.get(0).Id) {
                            System.Assert.areEqual(expectedLimit, ipsu.reduivy__Attempt_Limit__c);
                            System.Assert.areEqual(expectedLimitStatus, ipsu.reduivy__Attempt_Limit_Status__c);
                        } else {
                            //this will use the program unit setting which is 3
                            System.Assert.areEqual(3, ipsu.reduivy__Attempt_Limit__c);
                            System.Assert.areEqual(true, ipsu.reduivy__Attempt_Limit_Status__c == IPS_Helper.ATTEMPT_LIMIT_STATUS_ATLIMIT || ipsu.reduivy__Attempt_Limit_Status__c == IPS_Helper.ATTEMPT_LIMIT_STATUS_BELOWLIMIT);
                        }
                    } else {
                        System.Assert.areEqual(expectedLimit, ipsu.reduivy__Attempt_Limit__c);
                        System.Assert.areEqual(expectedLimitStatus, ipsu.reduivy__Attempt_Limit_Status__c);
                    }

                    foundIpsu = true;
                }

                System.Assert.isTrue(foundIpsu, 'No ips unit found for assertion.');

            } catch (Exception exp) {
                System.Assert.fail('Unexpected error: ' + exp.getMessage());
            }
        } else {
            try {
                Integer counter = 0;
                for(Database.SaveResult sr : Database.insert(ienInsertList, false, AccessLevel.USER_MODE)) {

                    String errorMsg = String.format(Label.Unit_Enrollment_Exceeded_Max_Attempt_Allowed, new List<String>{'BUS101', String.valueOf(sesLimit)});

                    if (testName == 'SES IPE' || testName == 'SES IPE Unit') {
                        //for ipe test, only the first ipe has study enrollment setting that will cause failure
                        if (counter == 0) {
                            System.Assert.areEqual(false, sr.isSuccess());
                            System.Assert.areEqual(errorMsg, sr.getErrors()[0].getMessage());
                        } else {
                            System.Assert.areEqual(true, sr.isSuccess());
                        }
                    } else {
                        System.Assert.areEqual(false, sr.isSuccess());
                        System.Assert.areEqual(errorMsg, sr.getErrors()[0].getMessage());
                    }

                    counter ++;
                }

            } catch (Exception exp) {
                System.Assert.fail('Unexpected error: ' + exp.getMessage());
            }
        }        
    }
}
