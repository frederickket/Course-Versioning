/**
 * @author      WDCi (XW)
 * @date        Sept 2025
 * @group       Test
 * @description Test class for ISD_ScoreRollup_EXE
 * @changehistory
 * ISS-002506 13-08-2025 XW - new class
 */
@IsTest
public inherited sharing class ISD_ScoreRollup_TEST {

    static final String STUDENT_CON = 'sandydoe@redu.example';
    static final String ISC_SRC = STUDENT_CON + '_SCF_Application';
    static final String SCF_SRC = 'SCF_Application';

    static final String ISD_LV1_1_SRC = ISC_SRC + '_SCR_CGPA';
    static final String ISD_LV1_PARENT_SRC = ISC_SRC + '_SCR_Additional Academic Background';
    static final String ISD_LV2_1_SRC = ISC_SRC + '_SCR_Official university master\'s degree';
    static final String ISD_LV2_2_SRC = ISC_SRC + '_SCR_Other continuing education master\'s degree (from 60 to 120 ECTS)';
    static final String ISD_LV2_PARENT_SRC = ISC_SRC + '_SCR_Doctoral studies related to clinical and health psychology';
    static final String ISD_LV3_1_SRC = ISC_SRC + '_SCR_Doctoral degree (PhD)';
    static final String ISD_LV3_2_SRC = ISC_SRC + '_SCR_Diploma of Advanced Studies (Spanish DEA) / 32 ECTS in research';
    static final String ISD_LV3_3_SRC = ISC_SRC + '_SCR_Teaching period';
    static final String ISD_LV1_3_SRC = ISC_SRC + '_SCR_English Proficiency';

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    /**
     * @description Default method to setup required data for automated test
     */
	@TestSetup
    static void makeData(){
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        // Create settings
        testFactory.setupDefaultSettings();

        // Create test data
        User ADMIN_USER = testFactory.getReduAdminUser();
		System.runAs(ADMIN_USER) {
            Test.startTest();
        	
            testFactory.initMasterData(SCR_Helper.getApiName());
            testFactory.initOfferingData(SIT_Helper.getApiName());
            testFactory.initStudentData(ISD_Helper.getApiName(), true);
            
            Test.stopTest();
		}

    }
	
    /**
     * @description Test as admin for inserting 1 score detail 
     */
    @IsTest
    static void testForInsert_1ScoreDetail_AsAdmin() {

        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User ADMIN_USER = testFactory.getReduAdminUser();
        Test.startTest();
        reduivy__Individual_Score__c parentIsc = queryIsc();
        System.Assert.areEqual(0, parentIsc.reduivy__Total_Score__c, 'Wrong Total Score before inserting new individual score detail!');
        reduivy__Individual_Score_Detail__c isdToInsert = new reduivy__Individual_Score_Detail__c(
            reduivy__Status__c = ISD_Helper.STATUS_ACTIVE,
            reduivy__Individual_Score__c = parentIsc.Id,
            reduivy__Weight__c = 100,
            reduivy__Weighted_Score__c = 10
        );

        
		System.runAs(ADMIN_USER){
            insert isdToInsert;
		}
        
        reduivy__Individual_Score__c parentIscAfter = queryIsc();
        System.Assert.areEqual(10, parentIscAfter.reduivy__Total_Score__c, 'Wrong Total Score after inserted new individual score detail!');
        
        Test.stopTest();
		
    }
	
    /**
     * @description Test as admin for inserting 2 score detail 
     */
    @IsTest
    static void testForInsert_2ScoreDetail_AsAdmin() {

        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User ADMIN_USER = testFactory.getReduAdminUser();
        Test.startTest();
        reduivy__Individual_Score__c parentIsc = queryIsc();
        System.Assert.areEqual(0, parentIsc.reduivy__Total_Score__c, 'Wrong Total Score before inserting new individual score detail!');
        reduivy__Individual_Score_Detail__c isdToInsert1 = new reduivy__Individual_Score_Detail__c(
            reduivy__Status__c = ISD_Helper.STATUS_ACTIVE,
            reduivy__Individual_Score__c = parentIsc.Id,
            reduivy__Weight__c = 100,
            reduivy__Weighted_Score__c = 10
        );

        reduivy__Individual_Score_Detail__c isdToInsert2 = new reduivy__Individual_Score_Detail__c(
            reduivy__Status__c = ISD_Helper.STATUS_ACTIVE,
            reduivy__Individual_Score__c = parentIsc.Id,
            reduivy__Weight__c = 100,
            reduivy__Weighted_Score__c = 6
        );

        
		System.runAs(ADMIN_USER){
            insert new List<reduivy__Individual_Score_Detail__c> { isdToInsert1, isdToInsert2 };
		}
        
        reduivy__Individual_Score__c parentIscAfter = queryIsc();
        System.Assert.areEqual(16, parentIscAfter.reduivy__Total_Score__c, 'Wrong Total Score after inserted new individual score detail!');
        
        Test.stopTest();
		
    }
	
    /**
     * @description Test as admin for inserting 2 score detail, bulk
     */
    @IsTest
    static void testForBulkInsert_2ScoreDetail_AsAdmin() {

        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User ADMIN_USER = testFactory.getReduAdminUser();
        Test.startTest();
        reduivy__Individual_Score__c parentIsc = queryIsc();
        REDU_TriggerController.muteTriggers(new Set<String>{'ISC_IdvScoreDetailGeneration_EXE', 'ISD_LinkRequirement_EXE'});

        Integer iscSize = 100;
        List<reduivy__Individual_Score__c> iscList = new List<reduivy__Individual_Score__c>();
        //create 100 individual score
        for(Integer i = 1; i <= iscSize; i++) {
            iscList.add(
                new reduivy__Individual_Score__c(
                    reduivy__Study_Scoring_Config__c = parentIsc.reduivy__Study_Scoring_Config__c,
                    reduivy__Status__c = ISC_Helper.STATUS_ACTIVE,
                    Name = 'ISC ' + i,
                    reduivy__Sample_Record_Code__c = 'Bulk'
                )
            );
        }

        insert iscList;

        List<reduivy__Individual_Score_Detail__c> isdList = new List<reduivy__Individual_Score_Detail__c>();
        for(reduivy__Individual_Score__c isc : iscList) {
            for(Integer i = 1; i <= 2; i++) {
                isdList.add(
                    new reduivy__Individual_Score_Detail__c(
                        reduivy__Individual_Score__c = isc.Id,
                        reduivy__Status__c = ISD_Helper.STATUS_ACTIVE,
                        reduivy__Weight__c = 50,
                        reduivy__Weighted_Score__c = 30
                    )
                );
            }
        }

        System.runAs(ADMIN_USER) {
            insert isdList;
        }

        Integer actualIscSize = 0;
        for(reduivy__Individual_Score__c isc : [SELECT Id, reduivy__Total_Score__c FROM reduivy__Individual_Score__c WHERE reduivy__Sample_Record_Code__c = 'Bulk']) {
            System.Assert.areEqual(60, isc.reduivy__Total_Score__c, 'Wrong Total Score!');
            actualIscSize++;
        }
        System.Assert.areEqual(100, actualIscSize, 'Wrong inserted Individual Score size!');
        
        Test.stopTest();
		
    }

    /**
     * @description Test as admin for updating 1 score detail 
     */
    @IsTest
    static void testForUpdate_1ScoreDetail_AsAdmin() {

        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User ADMIN_USER = testFactory.getReduAdminUser();
        Test.startTest();
        reduivy__Individual_Score__c parentIsc = queryIsc();
        reduivy__Individual_Score_Detail__c isdToUpdate = queryIsd(ISD_LV1_1_SRC);
        System.Assert.areEqual(0, parentIsc.reduivy__Total_Score__c, 'Wrong Total Score before updating new individual score detail!');
        System.Assert.isTrue(isNullor0(isdToUpdate.reduivy__Weighted_Score__c), 'Wrong Weight Score before updating new individual score detail! Actual: ' + isdToUpdate.reduivy__Weighted_Score__c);
        
        isdToUpdate.reduivy__Weighted_Score__c = 10;
        System.runAs(ADMIN_USER) {
            update isdToUpdate;
        }
		
        reduivy__Individual_Score__c parentIscAfter = queryIsc();
        System.Assert.areEqual(10, parentIscAfter.reduivy__Total_Score__c, 'Wrong Total Score after updated new individual score detail!');

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for updating 2 score detail 
     */
    @IsTest
    static void testForUpdate_2ScoreDetail_AsAdmin() {

        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User ADMIN_USER = testFactory.getReduAdminUser();
        Test.startTest();
        reduivy__Individual_Score__c parentIsc = queryIsc();
        reduivy__Individual_Score_Detail__c isdToUpdate1 = queryIsd(ISD_LV1_1_SRC);
        reduivy__Individual_Score_Detail__c isdToUpdate2 = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(0, parentIsc.reduivy__Total_Score__c, 'Wrong Total Score before updating new individual score detail!');
        System.Assert.isTrue(isNullor0(isdToUpdate1.reduivy__Weighted_Score__c), 'Wrong Weight Score before updating new individual score detail! Actual: ' + isdToUpdate1.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdToUpdate2.reduivy__Weighted_Score__c), 'Wrong Weight Score before updating new individual score detail! Actual: ' + isdToUpdate2.reduivy__Weighted_Score__c);
        
        isdToUpdate1.reduivy__Weighted_Score__c = 10;
        isdToUpdate2.reduivy__Weighted_Score__c = 5;
        System.runAs(ADMIN_USER) {
            update new List<reduivy__Individual_Score_Detail__c> { isdToUpdate1, isdToUpdate2 };
        }
		
        reduivy__Individual_Score__c parentIscAfter = queryIsc();
        System.Assert.areEqual(15, parentIscAfter.reduivy__Total_Score__c, 'Wrong Total Score after updated new individual score detail!');

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for updating 1 score detail, change individual score
     */
    @IsTest
    static void testForUpdate_1ScoreDetail_ChangeParentScore_AsAdmin() {

        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User ADMIN_USER = testFactory.getReduAdminUser();
        Test.startTest();

        //create a new individual score
        reduivy__Individual_Score__c parentIsc = queryIsc();
        reduivy__Individual_Score__c newIsc = new reduivy__Individual_Score__c(
            reduivy__Individual_Program_Application__c = parentIsc.reduivy__Individual_Program_Application__c,
            reduivy__Status__c = ISC_Helper.STATUS_ACTIVE
        );

        insert newIsc;

        reduivy__Individual_Score_Detail__c isdToUpdate = queryIsd(ISD_LV1_1_SRC);
        System.Assert.areEqual(0, parentIsc.reduivy__Total_Score__c, 'Wrong Total Score before updating new individual score detail!');
        System.Assert.isTrue(isNullor0(newIsc.reduivy__Total_Score__c), 'Wrong Total Score before updating new individual score detail! Actual: ' + newIsc.reduivy__Total_Score__c);
        System.Assert.isTrue(isNullor0(isdToUpdate.reduivy__Weighted_Score__c), 'Wrong Weight Score before updating new individual score detail! Actual: ' + isdToUpdate.reduivy__Weighted_Score__c);
        
        isdToUpdate.reduivy__Weighted_Score__c = 10;
        update isdToUpdate;
		
        reduivy__Individual_Score__c parentIscAfter = queryIsc();
        reduivy__Individual_Score__c newIscAfter = [SELECT Id, reduivy__Total_Score__c FROM reduivy__Individual_Score__c WHERE Id =: newIsc.Id];
        System.Assert.areEqual(10, parentIscAfter.reduivy__Total_Score__c, 'Wrong Total Score after updated new individual score detail!');
        System.Assert.isTrue(isNullor0(newIscAfter.reduivy__Total_Score__c), 'Wrong Total Score after updated new individual score detail! Actual: ' + newIscAfter.reduivy__Total_Score__c);

        //change parent score here
        isdToUpdate.reduivy__Individual_Score__c = newisc.Id;
        System.runAs(ADMIN_USER) {
            update isdToUpdate;
        }

        reduivy__Individual_Score__c parentIscAfterChange = queryIsc();
        reduivy__Individual_Score__c newIscAfterChange = [SELECT Id, reduivy__Total_Score__c FROM reduivy__Individual_Score__c WHERE Id =: newIsc.Id];
        System.Assert.areEqual(0, parentIscAfterChange.reduivy__Total_Score__c, 'Wrong Total Score before updating new individual score detail!');
        System.Assert.areEqual(10, newIscAfterChange.reduivy__Total_Score__c, 'Wrong Total Score before updating new individual score detail!');
        
        

        Test.stopTest();
		
    }
    
    /**
     * @description Test as admin for updating 2 score detail, bulk
     */
    @IsTest
    static void testForBulkUpdate_2ScoreDetail_AsAdmin() {

        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User ADMIN_USER = testFactory.getReduAdminUser();
        Test.startTest();
        reduivy__Individual_Score__c parentIsc = queryIsc();
        REDU_TriggerController.muteTriggers(new Set<String>{'ISC_IdvScoreDetailGeneration_EXE', 'ISD_LinkRequirement_EXE'});

        Integer iscSize = 100;
        List<reduivy__Individual_Score__c> iscList = new List<reduivy__Individual_Score__c>();
        //create 100 individual score
        for(Integer i = 1; i <= iscSize; i++) {
            iscList.add(
                new reduivy__Individual_Score__c(
                    reduivy__Study_Scoring_Config__c = parentIsc.reduivy__Study_Scoring_Config__c,
                    reduivy__Status__c = ISC_Helper.STATUS_ACTIVE,
                    Name = 'ISC ' + i,
                    reduivy__Sample_Record_Code__c = 'Bulk'
                )
            );
        }

        insert iscList;

        List<reduivy__Individual_Score_Detail__c> isdList = new List<reduivy__Individual_Score_Detail__c>();
        List<reduivy__Individual_Score_Detail__c> isdListToUpdate = new List<reduivy__Individual_Score_Detail__c>();
        for(reduivy__Individual_Score__c isc : iscList) {
            for(Integer i = 1; i <= 2; i++) {
                reduivy__Individual_Score_Detail__c newIsd = new reduivy__Individual_Score_Detail__c(
                    reduivy__Individual_Score__c = isc.Id,
                    reduivy__Status__c = ISD_Helper.STATUS_ACTIVE,
                    reduivy__Weight__c = 50,
                    reduivy__Weighted_Score__c = 30
                );

                isdList.add(newIsd);
                if(i == 1) {
                    isdListToUpdate.add(newIsd);
                }
            }
        }

        insert isdList;
        Integer actualIscSize = 0;
        for(reduivy__Individual_Score__c isc : [SELECT Id, reduivy__Total_Score__c FROM reduivy__Individual_Score__c WHERE reduivy__Sample_Record_Code__c = 'Bulk']) {
            System.Assert.areEqual(60, isc.reduivy__Total_Score__c, 'Wrong Total Score!');
            actualIscSize++;
        }
        System.Assert.areEqual(100, actualIscSize, 'Wrong inserted Individual Score size!');


        for(reduivy__Individual_Score_Detail__c isdToUpdate : isdListToUpdate) {
            isdToUpdate.reduivy__Weighted_Score__c = 10;
        }

        System.runAs(ADMIN_USER) {
            update isdListToUpdate;
        }

        actualIscSize = 0;
        for(reduivy__Individual_Score__c isc : [SELECT Id, reduivy__Total_Score__c FROM reduivy__Individual_Score__c WHERE reduivy__Sample_Record_Code__c = 'Bulk']) {
            System.Assert.areEqual(40, isc.reduivy__Total_Score__c, 'Total Score should be updated to 40!');
            actualIscSize++;
        }
        System.Assert.areEqual(100, actualIscSize, 'Wrong inserted Individual Score size!');

        Test.stopTest();
		
    }


    /**
     * @description Test as admin for deleting and undeleting 1 score detail
     */
    @IsTest
    static void testForDeleteUndelete_1ScoreDetail_AsAdmin() {

        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User ADMIN_USER = testFactory.getReduAdminUser();
        Test.startTest();
        reduivy__Individual_Score__c parentIsc = queryIsc();
        reduivy__Individual_Score_Detail__c isdToDelete = queryIsd(ISD_LV1_1_SRC);
        System.Assert.areEqual(0, parentIsc.reduivy__Total_Score__c, 'Wrong Total Score before updating new individual score detail!');
        System.Assert.isTrue(isNullor0(isdToDelete.reduivy__Weighted_Score__c), 'Wrong Weight Score before updating new individual score detail! Actual: ' + isdToDelete.reduivy__Weighted_Score__c);
        
        isdToDelete.reduivy__Weighted_Score__c = 10;
        System.runAs(ADMIN_USER) {
            update isdToDelete;
        }
		
        reduivy__Individual_Score__c parentIscAfter = queryIsc();
        System.Assert.areEqual(10, parentIscAfter.reduivy__Total_Score__c, 'Wrong Total Score after updated new individual score detail!');

        System.runAs(ADMIN_USER) {
            delete isdToDelete;
        }
        
        reduivy__Individual_Score__c parentIscAfterDelete = queryIsc();
        System.Assert.areEqual(0, parentIscAfterDelete.reduivy__Total_Score__c, 'Wrong Total Score after deleted individual score detail!');

        System.runAs(ADMIN_USER) {
            undelete isdToDelete;
        }

        reduivy__Individual_Score__c parentIscAfterUndelete = queryIsc();
        System.Assert.areEqual(10, parentIscAfterUndelete.reduivy__Total_Score__c, 'Wrong Total Score after undeleted individual score detail!');

        Test.stopTest();
		
    }

    
    /**
     * @description Test as admin for deleting and undeleting 2 score detail 
     */
    @IsTest
    static void testForDeleteUndelete_2ScoreDetail_AsAdmin() {

        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User ADMIN_USER = testFactory.getReduAdminUser();
        Test.startTest();
        reduivy__Individual_Score__c parentIsc = queryIsc();
        reduivy__Individual_Score_Detail__c isdToDelete1 = queryIsd(ISD_LV1_1_SRC);
        reduivy__Individual_Score_Detail__c isdToDelete2 = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(0, parentIsc.reduivy__Total_Score__c, 'Wrong Total Score before updating individual score detail!');
        System.Assert.isTrue(isNullor0(isdToDelete1.reduivy__Weighted_Score__c), 'Wrong Weight Score before updating individual score detail! Actual: ' + isdToDelete1.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdToDelete2.reduivy__Weighted_Score__c), 'Wrong Weight Score before updating individual score detail! Actual: ' + isdToDelete2.reduivy__Weighted_Score__c);
        
        isdToDelete1.reduivy__Weighted_Score__c = 10;
        isdToDelete2.reduivy__Weighted_Score__c = 5;
        System.runAs(ADMIN_USER) {
            update new List<reduivy__Individual_Score_Detail__c> { isdToDelete1, isdToDelete2 };
        }
		
        reduivy__Individual_Score__c parentIscAfter = queryIsc();
        System.Assert.areEqual(15, parentIscAfter.reduivy__Total_Score__c, 'Wrong Total Score after updated individual score detail!');

        System.runAs(ADMIN_USER) {
            delete new List<reduivy__Individual_Score_Detail__c> { isdToDelete1, isdToDelete2 };
        }

        reduivy__Individual_Score__c parentIscAfterDelete = queryIsc();
        System.Assert.areEqual(0, parentIscAfterDelete.reduivy__Total_Score__c, 'Wrong Total Score after deleted individual score detail!');

        System.runAs(ADMIN_USER) {
            undelete new List<reduivy__Individual_Score_Detail__c> { isdToDelete1, isdToDelete2 };
        }

        reduivy__Individual_Score__c parentIscAfterUndelete = queryIsc();
        System.Assert.areEqual(15, parentIscAfterUndelete.reduivy__Total_Score__c, 'Wrong Total Score after undeleted new individual score detail!');


        Test.stopTest();
		
    }
    
    
    /**
     * @description Test as admin for deleting and undeleting 2 score detail, bulk
     */
    @IsTest
    static void testForBulkDeletingUndeleting_2ScoreDetail_AsAdmin() {

        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User ADMIN_USER = testFactory.getReduAdminUser();
        Test.startTest();
        reduivy__Individual_Score__c parentIsc = queryIsc();
        REDU_TriggerController.muteTriggers(new Set<String>{'ISC_IdvScoreDetailGeneration_EXE', 'ISD_LinkRequirement_EXE'});

        Integer iscSize = 100;
        List<reduivy__Individual_Score__c> iscList = new List<reduivy__Individual_Score__c>();
        //create 100 individual score
        for(Integer i = 1; i <= iscSize; i++) {
            iscList.add(
                new reduivy__Individual_Score__c(
                    reduivy__Study_Scoring_Config__c = parentIsc.reduivy__Study_Scoring_Config__c,
                    reduivy__Status__c = ISC_Helper.STATUS_ACTIVE,
                    Name = 'ISC ' + i,
                    reduivy__Sample_Record_Code__c = 'Bulk'
                )
            );
        }

        insert iscList;

        List<reduivy__Individual_Score_Detail__c> isdList = new List<reduivy__Individual_Score_Detail__c>();
        List<reduivy__Individual_Score_Detail__c> isdListToDelete = new List<reduivy__Individual_Score_Detail__c>();
        for(reduivy__Individual_Score__c isc : iscList) {
            for(Integer i = 1; i <= 2; i++) {
                reduivy__Individual_Score_Detail__c newIsd = new reduivy__Individual_Score_Detail__c(
                    reduivy__Individual_Score__c = isc.Id,
                    reduivy__Status__c = ISD_Helper.STATUS_ACTIVE,
                    reduivy__Weight__c = 50,
                    reduivy__Weighted_Score__c = 30
                );

                isdList.add(newIsd);
                if(i == 1) {
                    isdListToDelete.add(newIsd);
                }
            }
        }

        insert isdList;
        Integer actualIscSize = 0;
        for(reduivy__Individual_Score__c isc : [SELECT Id, reduivy__Total_Score__c FROM reduivy__Individual_Score__c WHERE reduivy__Sample_Record_Code__c = 'Bulk']) {
            System.Assert.areEqual(60, isc.reduivy__Total_Score__c, 'Wrong Total Score!');
            actualIscSize++;
        }
        System.Assert.areEqual(100, actualIscSize, 'Wrong inserted Individual Score size!');

        System.runAs(ADMIN_USER) {
            delete isdListToDelete;
        }

        actualIscSize = 0;
        for(reduivy__Individual_Score__c isc : [SELECT Id, reduivy__Total_Score__c FROM reduivy__Individual_Score__c WHERE reduivy__Sample_Record_Code__c = 'Bulk']) {
            System.Assert.areEqual(30, isc.reduivy__Total_Score__c, 'Total Score should be updated to 30!');
            actualIscSize++;
        }
        System.Assert.areEqual(100, actualIscSize, 'Wrong inserted Individual Score size!');

        System.runAs(ADMIN_USER) {
            undelete isdListToDelete;
        }

        actualIscSize = 0;
        for(reduivy__Individual_Score__c isc : [SELECT Id, reduivy__Total_Score__c FROM reduivy__Individual_Score__c WHERE reduivy__Sample_Record_Code__c = 'Bulk']) {
            System.Assert.areEqual(60, isc.reduivy__Total_Score__c, 'Total Score should be updated to 60!');
            actualIscSize++;
        }
        System.Assert.areEqual(100, actualIscSize, 'Wrong inserted Individual Score size!');



        Test.stopTest();
		
    }

    
	
    /**
     * @description Test as faculty for inserting 1 score detail 
     */
    @IsTest
    static void testForInsert_1ScoreDetail_AsFaculty() {

        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User FACULTY_USER = testFactory.getReduFacultyUser();
        Test.startTest();
        reduivy__Individual_Score__c parentIsc = queryIsc();
        System.Assert.areEqual(0, parentIsc.reduivy__Total_Score__c, 'Wrong Total Score before inserting new individual score detail!');
        reduivy__Individual_Score_Detail__c isdToInsert = new reduivy__Individual_Score_Detail__c(
            reduivy__Status__c = ISD_Helper.STATUS_ACTIVE,
            reduivy__Individual_Score__c = parentIsc.Id,
            reduivy__Weight__c = 100,
            reduivy__Weighted_Score__c = 10
        );

        
		System.runAs(FACULTY_USER){
            insert isdToInsert;
		}
        
        reduivy__Individual_Score__c parentIscAfter = queryIsc();
        System.Assert.areEqual(10, parentIscAfter.reduivy__Total_Score__c, 'Wrong Total Score after inserted new individual score detail!');
        
        Test.stopTest();
		
    }
	
    /**
     * @description Test as faculty for inserting 2 score detail 
     */
    @IsTest
    static void testForInsert_2ScoreDetail_AsFaculty() {

        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User FACULTY_USER = testFactory.getReduFacultyUser();
        Test.startTest();
        reduivy__Individual_Score__c parentIsc = queryIsc();
        System.Assert.areEqual(0, parentIsc.reduivy__Total_Score__c, 'Wrong Total Score before inserting new individual score detail!');
        reduivy__Individual_Score_Detail__c isdToInsert1 = new reduivy__Individual_Score_Detail__c(
            reduivy__Status__c = ISD_Helper.STATUS_ACTIVE,
            reduivy__Individual_Score__c = parentIsc.Id,
            reduivy__Weight__c = 100,
            reduivy__Weighted_Score__c = 10
        );

        reduivy__Individual_Score_Detail__c isdToInsert2 = new reduivy__Individual_Score_Detail__c(
            reduivy__Status__c = ISD_Helper.STATUS_ACTIVE,
            reduivy__Individual_Score__c = parentIsc.Id,
            reduivy__Weight__c = 100,
            reduivy__Weighted_Score__c = 6
        );

        
		System.runAs(FACULTY_USER){
            insert new List<reduivy__Individual_Score_Detail__c> { isdToInsert1, isdToInsert2 };
		}
        
        reduivy__Individual_Score__c parentIscAfter = queryIsc();
        System.Assert.areEqual(16, parentIscAfter.reduivy__Total_Score__c, 'Wrong Total Score after inserted new individual score detail!');
        
        Test.stopTest();
		
    }
	
    /**
     * @description Test as faculty for inserting 2 score detail, bulk
     */
    @IsTest
    static void testForBulkInsert_2ScoreDetail_AsFaculty() {

        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User FACULTY_USER = testFactory.getReduFacultyUser();
        Test.startTest();
        reduivy__Individual_Score__c parentIsc = queryIsc();
        REDU_TriggerController.muteTriggers(new Set<String>{'ISC_IdvScoreDetailGeneration_EXE', 'ISD_LinkRequirement_EXE'});

        Integer iscSize = 100;
        List<reduivy__Individual_Score__c> iscList = new List<reduivy__Individual_Score__c>();
        //create 100 individual score
        for(Integer i = 1; i <= iscSize; i++) {
            iscList.add(
                new reduivy__Individual_Score__c(
                    reduivy__Study_Scoring_Config__c = parentIsc.reduivy__Study_Scoring_Config__c,
                    reduivy__Status__c = ISC_Helper.STATUS_ACTIVE,
                    Name = 'ISC ' + i,
                    reduivy__Sample_Record_Code__c = 'Bulk'
                )
            );
        }

        insert iscList;

        List<reduivy__Individual_Score_Detail__c> isdList = new List<reduivy__Individual_Score_Detail__c>();
        for(reduivy__Individual_Score__c isc : iscList) {
            for(Integer i = 1; i <= 2; i++) {
                isdList.add(
                    new reduivy__Individual_Score_Detail__c(
                        reduivy__Individual_Score__c = isc.Id,
                        reduivy__Status__c = ISD_Helper.STATUS_ACTIVE,
                        reduivy__Weight__c = 50,
                        reduivy__Weighted_Score__c = 30
                    )
                );
            }
        }

        System.runAs(FACULTY_USER) {
            insert isdList;
        }

        Integer actualIscSize = 0;
        for(reduivy__Individual_Score__c isc : [SELECT Id, reduivy__Total_Score__c FROM reduivy__Individual_Score__c WHERE reduivy__Sample_Record_Code__c = 'Bulk']) {
            System.Assert.areEqual(60, isc.reduivy__Total_Score__c, 'Wrong Total Score!');
            actualIscSize++;
        }
        System.Assert.areEqual(100, actualIscSize, 'Wrong inserted Individual Score size!');
        
        Test.stopTest();
		
    }

    /**
     * @description Test as faculty for updating 1 score detail 
     */
    @IsTest
    static void testForUpdate_1ScoreDetail_AsFaculty() {

        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User FACULTY_USER = testFactory.getReduFacultyUser();
        Test.startTest();
        reduivy__Individual_Score__c parentIsc = queryIsc();
        reduivy__Individual_Score_Detail__c isdToUpdate = queryIsd(ISD_LV1_1_SRC);
        System.Assert.areEqual(0, parentIsc.reduivy__Total_Score__c, 'Wrong Total Score before updating new individual score detail!');
        System.Assert.isTrue(isNullor0(isdToUpdate.reduivy__Weighted_Score__c), 'Wrong Weight Score before updating new individual score detail! Actual: ' + isdToUpdate.reduivy__Weighted_Score__c);
        
        isdToUpdate.reduivy__Weighted_Score__c = 10;
        System.runAs(FACULTY_USER) {
            update isdToUpdate;
        }
		
        reduivy__Individual_Score__c parentIscAfter = queryIsc();
        System.Assert.areEqual(10, parentIscAfter.reduivy__Total_Score__c, 'Wrong Total Score after updated new individual score detail!');

        Test.stopTest();
		
    }

    /**
     * @description Test as faculty for updating 2 score detail 
     */
    @IsTest
    static void testForUpdate_2ScoreDetail_AsFaculty() {

        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User FACULTY_USER = testFactory.getReduFacultyUser();
        Test.startTest();
        reduivy__Individual_Score__c parentIsc = queryIsc();
        reduivy__Individual_Score_Detail__c isdToUpdate1 = queryIsd(ISD_LV1_1_SRC);
        reduivy__Individual_Score_Detail__c isdToUpdate2 = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(0, parentIsc.reduivy__Total_Score__c, 'Wrong Total Score before updating new individual score detail!');
        System.Assert.isTrue(isNullor0(isdToUpdate1.reduivy__Weighted_Score__c), 'Wrong Weight Score before updating new individual score detail! Actual: ' + isdToUpdate1.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdToUpdate2.reduivy__Weighted_Score__c), 'Wrong Weight Score before updating new individual score detail! Actual: ' + isdToUpdate2.reduivy__Weighted_Score__c);
        
        isdToUpdate1.reduivy__Weighted_Score__c = 10;
        isdToUpdate2.reduivy__Weighted_Score__c = 5;
        System.runAs(FACULTY_USER) {
            update new List<reduivy__Individual_Score_Detail__c> { isdToUpdate1, isdToUpdate2 };
        }
		
        reduivy__Individual_Score__c parentIscAfter = queryIsc();
        System.Assert.areEqual(15, parentIscAfter.reduivy__Total_Score__c, 'Wrong Total Score after updated new individual score detail!');

        Test.stopTest();
		
    }

    /**
     * @description Test as faculty for updating 1 score detail, change individual score
     */
    @IsTest
    static void testForUpdate_1ScoreDetail_ChangeParentScore_AsFaculty() {

        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User FACULTY_USER = testFactory.getReduFacultyUser();
        Test.startTest();

        //create a new individual score
        reduivy__Individual_Score__c parentIsc = queryIsc();
        reduivy__Individual_Score__c newIsc = new reduivy__Individual_Score__c(
            reduivy__Individual_Program_Application__c = parentIsc.reduivy__Individual_Program_Application__c,
            reduivy__Status__c = ISC_Helper.STATUS_ACTIVE
        );

        insert newIsc;

        reduivy__Individual_Score_Detail__c isdToUpdate = queryIsd(ISD_LV1_1_SRC);
        System.Assert.areEqual(0, parentIsc.reduivy__Total_Score__c, 'Wrong Total Score before updating new individual score detail!');
        System.Assert.isTrue(isNullor0(newIsc.reduivy__Total_Score__c), 'Wrong Total Score before updating new individual score detail! Actual: ' + newIsc.reduivy__Total_Score__c);
        System.Assert.isTrue(isNullor0(isdToUpdate.reduivy__Weighted_Score__c), 'Wrong Weight Score before updating new individual score detail! Actual: ' + isdToUpdate.reduivy__Weighted_Score__c);
        
        isdToUpdate.reduivy__Weighted_Score__c = 10;
        update isdToUpdate;
		
        reduivy__Individual_Score__c parentIscAfter = queryIsc();
        reduivy__Individual_Score__c newIscAfter = [SELECT Id, reduivy__Total_Score__c FROM reduivy__Individual_Score__c WHERE Id =: newIsc.Id];
        System.Assert.areEqual(10, parentIscAfter.reduivy__Total_Score__c, 'Wrong Total Score after updated new individual score detail!');
        System.Assert.isTrue(isNullor0(newIscAfter.reduivy__Total_Score__c), 'Wrong Total Score after updated new individual score detail! Actual: ' + newIscAfter.reduivy__Total_Score__c);

        //change parent score here
        isdToUpdate.reduivy__Individual_Score__c = newisc.Id;
        System.runAs(FACULTY_USER) {
            update isdToUpdate;
        }

        reduivy__Individual_Score__c parentIscAfterChange = queryIsc();
        reduivy__Individual_Score__c newIscAfterChange = [SELECT Id, reduivy__Total_Score__c FROM reduivy__Individual_Score__c WHERE Id =: newIsc.Id];
        System.Assert.areEqual(0, parentIscAfterChange.reduivy__Total_Score__c, 'Wrong Total Score before updating new individual score detail!');
        System.Assert.areEqual(10, newIscAfterChange.reduivy__Total_Score__c, 'Wrong Total Score before updating new individual score detail!');
        
        

        Test.stopTest();
		
    }
    
    /**
     * @description Test as faculty for updating 2 score detail, bulk
     */
    @IsTest
    static void testForBulkUpdate_2ScoreDetail_AsFaculty() {

        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User FACULTY_USER = testFactory.getReduFacultyUser();
        Test.startTest();
        reduivy__Individual_Score__c parentIsc = queryIsc();
        REDU_TriggerController.muteTriggers(new Set<String>{'ISC_IdvScoreDetailGeneration_EXE', 'ISD_LinkRequirement_EXE'});

        Integer iscSize = 100;
        List<reduivy__Individual_Score__c> iscList = new List<reduivy__Individual_Score__c>();
        //create 100 individual score
        for(Integer i = 1; i <= iscSize; i++) {
            iscList.add(
                new reduivy__Individual_Score__c(
                    reduivy__Study_Scoring_Config__c = parentIsc.reduivy__Study_Scoring_Config__c,
                    reduivy__Status__c = ISC_Helper.STATUS_ACTIVE,
                    Name = 'ISC ' + i,
                    reduivy__Sample_Record_Code__c = 'Bulk'
                )
            );
        }

        insert iscList;

        List<reduivy__Individual_Score_Detail__c> isdList = new List<reduivy__Individual_Score_Detail__c>();
        List<reduivy__Individual_Score_Detail__c> isdListToUpdate = new List<reduivy__Individual_Score_Detail__c>();
        for(reduivy__Individual_Score__c isc : iscList) {
            for(Integer i = 1; i <= 2; i++) {
                reduivy__Individual_Score_Detail__c newIsd = new reduivy__Individual_Score_Detail__c(
                    reduivy__Individual_Score__c = isc.Id,
                    reduivy__Status__c = ISD_Helper.STATUS_ACTIVE,
                    reduivy__Weight__c = 50,
                    reduivy__Weighted_Score__c = 30
                );

                isdList.add(newIsd);
                if(i == 1) {
                    isdListToUpdate.add(newIsd);
                }
            }
        }

        insert isdList;
        Integer actualIscSize = 0;
        for(reduivy__Individual_Score__c isc : [SELECT Id, reduivy__Total_Score__c FROM reduivy__Individual_Score__c WHERE reduivy__Sample_Record_Code__c = 'Bulk']) {
            System.Assert.areEqual(60, isc.reduivy__Total_Score__c, 'Wrong Total Score!');
            actualIscSize++;
        }
        System.Assert.areEqual(100, actualIscSize, 'Wrong inserted Individual Score size!');


        for(reduivy__Individual_Score_Detail__c isdToUpdate : isdListToUpdate) {
            isdToUpdate.reduivy__Weighted_Score__c = 10;
        }

        System.runAs(FACULTY_USER) {
            update isdListToUpdate;
        }

        actualIscSize = 0;
        for(reduivy__Individual_Score__c isc : [SELECT Id, reduivy__Total_Score__c FROM reduivy__Individual_Score__c WHERE reduivy__Sample_Record_Code__c = 'Bulk']) {
            System.Assert.areEqual(40, isc.reduivy__Total_Score__c, 'Total Score should be updated to 40!');
            actualIscSize++;
        }
        System.Assert.areEqual(100, actualIscSize, 'Wrong inserted Individual Score size!');

        Test.stopTest();
		
    }


    @IsTest
    static void testForDeleteUndelete_1ScoreDetail_AsFaculty() {

        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User FACULTY_USER = testFactory.getReduFacultyUser();
        Test.startTest();
        reduivy__Individual_Score__c parentIsc = queryIsc();
        reduivy__Individual_Score_Detail__c isdToDelete = queryIsd(ISD_LV1_1_SRC);
        System.Assert.areEqual(0, parentIsc.reduivy__Total_Score__c, 'Wrong Total Score before updating new individual score detail!');
        System.Assert.isTrue(isNullor0(isdToDelete.reduivy__Weighted_Score__c), 'Wrong Weight Score before updating new individual score detail! Actual: ' + isdToDelete.reduivy__Weighted_Score__c);
        
        isdToDelete.reduivy__Weighted_Score__c = 10;
        System.runAs(FACULTY_USER) {
            update isdToDelete;
        }
		
        reduivy__Individual_Score__c parentIscAfter = queryIsc();
        System.Assert.areEqual(10, parentIscAfter.reduivy__Total_Score__c, 'Wrong Total Score after updated new individual score detail!');

        System.runAs(FACULTY_USER) {
            delete isdToDelete;
        }
        
        reduivy__Individual_Score__c parentIscAfterDelete = queryIsc();
        System.Assert.areEqual(0, parentIscAfterDelete.reduivy__Total_Score__c, 'Wrong Total Score after deleted individual score detail!');

        System.runAs(FACULTY_USER) {
            undelete isdToDelete;
        }

        reduivy__Individual_Score__c parentIscAfterUndelete = queryIsc();
        System.Assert.areEqual(10, parentIscAfterUndelete.reduivy__Total_Score__c, 'Wrong Total Score after undeleted individual score detail!');

        Test.stopTest();
		
    }

    
    /**
     * @description Test as faculty for updating 2 score detail 
     */
    @IsTest
    static void testForDeleteUndelete_2ScoreDetail_AsFaculty() {

        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User FACULTY_USER = testFactory.getReduFacultyUser();
        Test.startTest();
        reduivy__Individual_Score__c parentIsc = queryIsc();
        reduivy__Individual_Score_Detail__c isdToDelete1 = queryIsd(ISD_LV1_1_SRC);
        reduivy__Individual_Score_Detail__c isdToDelete2 = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(0, parentIsc.reduivy__Total_Score__c, 'Wrong Total Score before updating individual score detail!');
        System.Assert.isTrue(isNullor0(isdToDelete1.reduivy__Weighted_Score__c), 'Wrong Weight Score before updating individual score detail! Actual: ' + isdToDelete1.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdToDelete2.reduivy__Weighted_Score__c), 'Wrong Weight Score before updating individual score detail! Actual: ' + isdToDelete2.reduivy__Weighted_Score__c);
        
        isdToDelete1.reduivy__Weighted_Score__c = 10;
        isdToDelete2.reduivy__Weighted_Score__c = 5;
        System.runAs(FACULTY_USER) {
            update new List<reduivy__Individual_Score_Detail__c> { isdToDelete1, isdToDelete2 };
        }
		
        reduivy__Individual_Score__c parentIscAfter = queryIsc();
        System.Assert.areEqual(15, parentIscAfter.reduivy__Total_Score__c, 'Wrong Total Score after updated individual score detail!');

        System.runAs(FACULTY_USER) {
            delete new List<reduivy__Individual_Score_Detail__c> { isdToDelete1, isdToDelete2 };
        }

        reduivy__Individual_Score__c parentIscAfterDelete = queryIsc();
        System.Assert.areEqual(0, parentIscAfterDelete.reduivy__Total_Score__c, 'Wrong Total Score after deleted individual score detail!');

        System.runAs(FACULTY_USER) {
            undelete new List<reduivy__Individual_Score_Detail__c> { isdToDelete1, isdToDelete2 };
        }

        reduivy__Individual_Score__c parentIscAfterUndelete = queryIsc();
        System.Assert.areEqual(15, parentIscAfterUndelete.reduivy__Total_Score__c, 'Wrong Total Score after undeleted new individual score detail!');


        Test.stopTest();
		
    }
    
    
    /**
     * @description Test as faculty for deleting and undeleting 2 score detail, bulk
     */
    @IsTest
    static void testForBulkDeletingUndeleting_2ScoreDetail_AsFaculty() {

        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User FACULTY_USER = testFactory.getReduFacultyUser();
        Test.startTest();
        reduivy__Individual_Score__c parentIsc = queryIsc();
        REDU_TriggerController.muteTriggers(new Set<String>{'ISC_IdvScoreDetailGeneration_EXE', 'ISD_LinkRequirement_EXE'});

        Integer iscSize = 100;
        List<reduivy__Individual_Score__c> iscList = new List<reduivy__Individual_Score__c>();
        //create 100 individual score
        for(Integer i = 1; i <= iscSize; i++) {
            iscList.add(
                new reduivy__Individual_Score__c(
                    reduivy__Study_Scoring_Config__c = parentIsc.reduivy__Study_Scoring_Config__c,
                    reduivy__Status__c = ISC_Helper.STATUS_ACTIVE,
                    Name = 'ISC ' + i,
                    reduivy__Sample_Record_Code__c = 'Bulk'
                )
            );
        }

        insert iscList;

        List<reduivy__Individual_Score_Detail__c> isdList = new List<reduivy__Individual_Score_Detail__c>();
        List<reduivy__Individual_Score_Detail__c> isdListToDelete = new List<reduivy__Individual_Score_Detail__c>();
        for(reduivy__Individual_Score__c isc : iscList) {
            for(Integer i = 1; i <= 2; i++) {
                reduivy__Individual_Score_Detail__c newIsd = new reduivy__Individual_Score_Detail__c(
                    reduivy__Individual_Score__c = isc.Id,
                    reduivy__Status__c = ISD_Helper.STATUS_ACTIVE,
                    reduivy__Weight__c = 50,
                    reduivy__Weighted_Score__c = 30
                );

                isdList.add(newIsd);
                if(i == 1) {
                    isdListToDelete.add(newIsd);
                }
            }
        }

        insert isdList;
        Integer actualIscSize = 0;
        for(reduivy__Individual_Score__c isc : [SELECT Id, reduivy__Total_Score__c FROM reduivy__Individual_Score__c WHERE reduivy__Sample_Record_Code__c = 'Bulk']) {
            System.Assert.areEqual(60, isc.reduivy__Total_Score__c, 'Wrong Total Score!');
            actualIscSize++;
        }
        System.Assert.areEqual(100, actualIscSize, 'Wrong inserted Individual Score size!');

        System.runAs(FACULTY_USER) {
            delete isdListToDelete;
        }

        actualIscSize = 0;
        for(reduivy__Individual_Score__c isc : [SELECT Id, reduivy__Total_Score__c FROM reduivy__Individual_Score__c WHERE reduivy__Sample_Record_Code__c = 'Bulk']) {
            System.Assert.areEqual(30, isc.reduivy__Total_Score__c, 'Total Score should be updated to 30!');
            actualIscSize++;
        }
        System.Assert.areEqual(100, actualIscSize, 'Wrong inserted Individual Score size!');

        System.runAs(FACULTY_USER) {
            undelete isdListToDelete;
        }

        actualIscSize = 0;
        for(reduivy__Individual_Score__c isc : [SELECT Id, reduivy__Total_Score__c FROM reduivy__Individual_Score__c WHERE reduivy__Sample_Record_Code__c = 'Bulk']) {
            System.Assert.areEqual(60, isc.reduivy__Total_Score__c, 'Total Score should be updated to 60!');
            actualIscSize++;
        }
        System.Assert.areEqual(100, actualIscSize, 'Wrong inserted Individual Score size!');



        Test.stopTest();
		
    }

    
	
    /**
     * @description Test as student for inserting 1 score detail 
     */
    @IsTest
    static void testForInsert_1ScoreDetail_AsStudent() {

        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User studentUser = testFactory.getStudentUser();
        Test.startTest();
        reduivy__Individual_Score__c parentIsc = queryIsc();
        System.Assert.areEqual(0, parentIsc.reduivy__Total_Score__c, 'Wrong Total Score before inserting new individual score detail!');
        reduivy__Individual_Score_Detail__c isdToInsert = new reduivy__Individual_Score_Detail__c(
            reduivy__Status__c = ISD_Helper.STATUS_ACTIVE,
            reduivy__Individual_Score__c = parentIsc.Id,
            reduivy__Weight__c = 100,
            reduivy__Weighted_Score__c = 10
        );

        
		System.runAs(studentUser){
            insert isdToInsert;
		}
        
        reduivy__Individual_Score__c parentIscAfter = queryIsc();
        System.Assert.areEqual(10, parentIscAfter.reduivy__Total_Score__c, 'Wrong Total Score after inserted new individual score detail!');
        
        Test.stopTest();
		
    }
	
    /**
     * @description Test as student for inserting 2 score detail 
     */
    @IsTest
    static void testForInsert_2ScoreDetail_AsStudent() {

        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User studentUser = testFactory.getStudentUser();
        Test.startTest();
        reduivy__Individual_Score__c parentIsc = queryIsc();
        System.Assert.areEqual(0, parentIsc.reduivy__Total_Score__c, 'Wrong Total Score before inserting new individual score detail!');
        reduivy__Individual_Score_Detail__c isdToInsert1 = new reduivy__Individual_Score_Detail__c(
            reduivy__Status__c = ISD_Helper.STATUS_ACTIVE,
            reduivy__Individual_Score__c = parentIsc.Id,
            reduivy__Weight__c = 100,
            reduivy__Weighted_Score__c = 10
        );

        reduivy__Individual_Score_Detail__c isdToInsert2 = new reduivy__Individual_Score_Detail__c(
            reduivy__Status__c = ISD_Helper.STATUS_ACTIVE,
            reduivy__Individual_Score__c = parentIsc.Id,
            reduivy__Weight__c = 100,
            reduivy__Weighted_Score__c = 6
        );

        
		System.runAs(studentUser){
            insert new List<reduivy__Individual_Score_Detail__c> { isdToInsert1, isdToInsert2 };
		}
        
        reduivy__Individual_Score__c parentIscAfter = queryIsc();
        System.Assert.areEqual(16, parentIscAfter.reduivy__Total_Score__c, 'Wrong Total Score after inserted new individual score detail!');
        
        Test.stopTest();
		
    }
	
    /**
     * @description Test as student for updating 1 score detail 
     */
    @IsTest
    static void testForUpdate_1ScoreDetail_AsStudent() {

        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User studentUser = testFactory.getStudentUser();
        Test.startTest();
        reduivy__Individual_Score__c parentIsc = queryIsc();
        reduivy__Individual_Score_Detail__c isdToUpdate = queryIsd(ISD_LV1_1_SRC);
        System.Assert.areEqual(0, parentIsc.reduivy__Total_Score__c, 'Wrong Total Score before updating new individual score detail!');
        System.Assert.isTrue(isNullor0(isdToUpdate.reduivy__Weighted_Score__c), 'Wrong Weight Score before updating new individual score detail! Actual: ' + isdToUpdate.reduivy__Weighted_Score__c);
        
        isdToUpdate.reduivy__Weighted_Score__c = 10;
        System.runAs(studentUser) {
            update isdToUpdate;
        }
		
        reduivy__Individual_Score__c parentIscAfter = queryIsc();
        System.Assert.areEqual(10, parentIscAfter.reduivy__Total_Score__c, 'Wrong Total Score after updated new individual score detail!');

        Test.stopTest();
		
    }

    /**
     * @description Test as student for updating 2 score detail 
     */
    @IsTest
    static void testForUpdate_2ScoreDetail_AsStudent() {

        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User studentUser = testFactory.getStudentUser();
        Test.startTest();
        reduivy__Individual_Score__c parentIsc = queryIsc();
        reduivy__Individual_Score_Detail__c isdToUpdate1 = queryIsd(ISD_LV1_1_SRC);
        reduivy__Individual_Score_Detail__c isdToUpdate2 = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(0, parentIsc.reduivy__Total_Score__c, 'Wrong Total Score before updating new individual score detail!');
        System.Assert.isTrue(isNullor0(isdToUpdate1.reduivy__Weighted_Score__c), 'Wrong Weight Score before updating new individual score detail! Actual: ' + isdToUpdate1.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdToUpdate2.reduivy__Weighted_Score__c), 'Wrong Weight Score before updating new individual score detail! Actual: ' + isdToUpdate2.reduivy__Weighted_Score__c);
        
        isdToUpdate1.reduivy__Weighted_Score__c = 10;
        isdToUpdate2.reduivy__Weighted_Score__c = 5;
        System.runAs(studentUser) {
            update new List<reduivy__Individual_Score_Detail__c> { isdToUpdate1, isdToUpdate2 };
        }
		
        reduivy__Individual_Score__c parentIscAfter = queryIsc();
        System.Assert.areEqual(15, parentIscAfter.reduivy__Total_Score__c, 'Wrong Total Score after updated new individual score detail!');

        Test.stopTest();
		
    }

    /**
     * @description Test as student for updating 1 score detail, change individual score
     */
    @IsTest
    static void testForUpdate_1ScoreDetail_ChangeParentScore_AsStudent() {

        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User studentUser = testFactory.getStudentUser();
        Test.startTest();

        //create a new individual score
        reduivy__Individual_Score__c parentIsc = queryIsc();
        reduivy__Individual_Score__c newIsc = new reduivy__Individual_Score__c(
            reduivy__Individual_Program_Application__c = parentIsc.reduivy__Individual_Program_Application__c,
            reduivy__Status__c = ISC_Helper.STATUS_ACTIVE,
            reduivy__Contact__c = parentIsc.reduivy__Contact__c
        );

        insert newIsc;

        reduivy__Individual_Score_Detail__c isdToUpdate = queryIsd(ISD_LV1_1_SRC);
        System.Assert.areEqual(0, parentIsc.reduivy__Total_Score__c, 'Wrong Total Score before updating new individual score detail!');
        System.Assert.isTrue(isNullor0(newIsc.reduivy__Total_Score__c), 'Wrong Total Score before updating new individual score detail! Actual: ' + newIsc.reduivy__Total_Score__c);
        System.Assert.isTrue(isNullor0(isdToUpdate.reduivy__Weighted_Score__c), 'Wrong Weight Score before updating new individual score detail! Actual: ' + isdToUpdate.reduivy__Weighted_Score__c);
        
        isdToUpdate.reduivy__Weighted_Score__c = 10;
        update isdToUpdate;
		
        reduivy__Individual_Score__c parentIscAfter = queryIsc();
        reduivy__Individual_Score__c newIscAfter = [SELECT Id, reduivy__Total_Score__c FROM reduivy__Individual_Score__c WHERE Id =: newIsc.Id];
        System.Assert.areEqual(10, parentIscAfter.reduivy__Total_Score__c, 'Wrong Total Score after updated new individual score detail!');
        System.Assert.isTrue(isNullor0(newIscAfter.reduivy__Total_Score__c), 'Wrong Total Score after updated new individual score detail! Actual: ' + newIscAfter.reduivy__Total_Score__c);

        //change parent score here
        isdToUpdate.reduivy__Individual_Score__c = newisc.Id;
        System.runAs(studentUser) {
            update isdToUpdate;
        }

        reduivy__Individual_Score__c parentIscAfterChange = queryIsc();
        reduivy__Individual_Score__c newIscAfterChange = [SELECT Id, reduivy__Total_Score__c FROM reduivy__Individual_Score__c WHERE Id =: newIsc.Id];
        System.Assert.areEqual(0, parentIscAfterChange.reduivy__Total_Score__c, 'Wrong Total Score before updating new individual score detail!');
        System.Assert.areEqual(10, newIscAfterChange.reduivy__Total_Score__c, 'Wrong Total Score before updating new individual score detail!');
        
        

        Test.stopTest();
		
    }
    
    @IsTest
    static void testForDeleteUndelete_1ScoreDetail_AsStudent() {

        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User studentUser = testFactory.getStudentUser();
        Test.startTest();
        reduivy__Individual_Score__c parentIsc = queryIsc();
        reduivy__Individual_Score_Detail__c isdToDelete = queryIsd(ISD_LV1_1_SRC);
        System.Assert.areEqual(0, parentIsc.reduivy__Total_Score__c, 'Wrong Total Score before updating new individual score detail!');
        System.Assert.isTrue(isNullor0(isdToDelete.reduivy__Weighted_Score__c), 'Wrong Weight Score before updating new individual score detail! Actual: ' + isdToDelete.reduivy__Weighted_Score__c);
        
        isdToDelete.reduivy__Weighted_Score__c = 10;
        System.runAs(studentUser) {
            update isdToDelete;
        }
		
        reduivy__Individual_Score__c parentIscAfter = queryIsc();
        System.Assert.areEqual(10, parentIscAfter.reduivy__Total_Score__c, 'Wrong Total Score after updated new individual score detail!');

        System.runAs(studentUser) {
            delete isdToDelete;
        }
        
        reduivy__Individual_Score__c parentIscAfterDelete = queryIsc();
        System.Assert.areEqual(0, parentIscAfterDelete.reduivy__Total_Score__c, 'Wrong Total Score after deleted individual score detail!');

        System.runAs(studentUser) {
            undelete isdToDelete;
        }

        reduivy__Individual_Score__c parentIscAfterUndelete = queryIsc();
        System.Assert.areEqual(10, parentIscAfterUndelete.reduivy__Total_Score__c, 'Wrong Total Score after undeleted individual score detail!');

        Test.stopTest();
		
    }

    
    /**
     * @description Test as student for updating 2 score detail 
     */
    @IsTest
    static void testForDeleteUndelete_2ScoreDetail_AsStudent() {

        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }

        User studentUser = testFactory.getStudentUser();
        Test.startTest();
        reduivy__Individual_Score__c parentIsc = queryIsc();
        reduivy__Individual_Score_Detail__c isdToDelete1 = queryIsd(ISD_LV1_1_SRC);
        reduivy__Individual_Score_Detail__c isdToDelete2 = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(0, parentIsc.reduivy__Total_Score__c, 'Wrong Total Score before updating individual score detail!');
        System.Assert.isTrue(isNullor0(isdToDelete1.reduivy__Weighted_Score__c), 'Wrong Weight Score before updating individual score detail! Actual: ' + isdToDelete1.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdToDelete2.reduivy__Weighted_Score__c), 'Wrong Weight Score before updating individual score detail! Actual: ' + isdToDelete2.reduivy__Weighted_Score__c);
        
        isdToDelete1.reduivy__Weighted_Score__c = 10;
        isdToDelete2.reduivy__Weighted_Score__c = 5;
        System.runAs(studentUser) {
            update new List<reduivy__Individual_Score_Detail__c> { isdToDelete1, isdToDelete2 };
        }
		
        reduivy__Individual_Score__c parentIscAfter = queryIsc();
        System.Assert.areEqual(15, parentIscAfter.reduivy__Total_Score__c, 'Wrong Total Score after updated individual score detail!');

        System.runAs(studentUser) {
            delete new List<reduivy__Individual_Score_Detail__c> { isdToDelete1, isdToDelete2 };
        }

        reduivy__Individual_Score__c parentIscAfterDelete = queryIsc();
        System.Assert.areEqual(0, parentIscAfterDelete.reduivy__Total_Score__c, 'Wrong Total Score after deleted individual score detail!');

        System.runAs(studentUser) {
            undelete new List<reduivy__Individual_Score_Detail__c> { isdToDelete1, isdToDelete2 };
        }

        reduivy__Individual_Score__c parentIscAfterUndelete = queryIsc();
        System.Assert.areEqual(15, parentIscAfterUndelete.reduivy__Total_Score__c, 'Wrong Total Score after undeleted new individual score detail!');


        Test.stopTest();
		
    }


    static Boolean isNullor0(Decimal value) {
        return value == null || value == 0;
    }
    
    static reduivy__Individual_Score_Detail__c queryIsd(String isdSrc) {
        return [
            SELECT Id, Name, reduivy__Weight__c, reduivy__Weighted_Score__c, reduivy__Max_Score__c, reduivy__Score__c, reduivy__Parent_Score_Detail__c
            FROM reduivy__Individual_Score_Detail__c
            WHERE reduivy__Sample_Record_Code__c = :isdSrc
            LIMIT 1
        ];
    }

    static reduivy__Individual_Score__c queryIsc() {
        return [
            SELECT Id, Name, reduivy__Total_Score__c, reduivy__Individual_Program_Application__c, reduivy__Study_Scoring_Config__c, reduivy__Contact__c
            FROM reduivy__Individual_Score__c 
            WHERE reduivy__Sample_Record_Code__c =: ISC_SRC
            LIMIT 1
        ];
    }
	
    static reduivy__Study_Scoring_Config__c queryScf() {
        return [
            SELECT Id, Name
            FROM reduivy__Study_Scoring_Config__c
            WHERE reduivy__Sample_Record_Code__c =: SCF_SRC
            LIMIT 1
        ];
    }
    
}