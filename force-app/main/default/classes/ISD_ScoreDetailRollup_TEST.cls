/**
 * @author      WDCi (XW)
 * @date        Aug 2025
 * @group       Test
 * @description Test class for ISD_ScoreDetailRollup_EXE
 * @changehistory
 * ISS-002506 12-08-2025 XW - new class
 */
@IsTest
public inherited sharing class ISD_ScoreDetailRollup_TEST {

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
        	
            //please adjust the data according to your needs
            testFactory.initMasterData(SCR_Helper.getApiName());
            testFactory.initOfferingData(SIT_Helper.getApiName());
            testFactory.initStudentData(ISD_Helper.getApiName(), true);
            
            Test.stopTest();
		}

    }
    
    /**
     * @description Test as admin for inserting weighted score of 1 lv2 children score details
     */
	@IsTest
    static void testForInsert_1WeightedScoreLv2_AsAdmin(){
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        Test.startTest();

        reduivy__Individual_Score__c parentIsc = queryIsc();
        reduivy__Individual_Score_Detail__c isd_lv1_parentBefore = queryIsd(ISD_LV1_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdToInsert = new reduivy__Individual_Score_Detail__c(
            reduivy__Individual_Score__c = parentIsc.Id,
            reduivy__Parent_Score_Detail__c = isd_lv1_parentBefore.Id,
            reduivy__Weighted_Score__c = 10,
            reduivy__Weight__c = 100,
            reduivy__Status__c = ISD_Helper.STATUS_ACTIVE
        );

        System.Assert.isTrue(isNullor0(isd_lv1_parentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the parent Individual Score Detail should be 0 before inserting! Actual: ' + isd_lv1_parentBefore.reduivy__Weighted_Score__c);

        System.runAs(ADMIN_USER) {
            insert isdToInsert;
        }

        reduivy__Individual_Score_Detail__c isd_lv1_parentAfter = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdToInsert.reduivy__Weighted_Score__c, 'Weighted Score of the child Individual Score Detail should be 10 after inserted!');
        System.Assert.areEqual(10, isd_lv1_parentAfter.reduivy__Weighted_Score__c, 'Weighted Score of the parent Individual Score Detail should be 10 after inserted!');

        Test.stopTest();
    }

    /**
     * @description Test as admin for inserting weighted score of 2 lv2 children score details
     */
	@IsTest
    static void testForInsert_2WeightedScoreLv2_AsAdmin(){
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        Test.startTest();

        reduivy__Individual_Score__c parentIsc = queryIsc();
        reduivy__Individual_Score_Detail__c isd_lv1_parentBefore = queryIsd(ISD_LV1_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdToInsert1 = new reduivy__Individual_Score_Detail__c(
            reduivy__Individual_Score__c = parentIsc.Id,
            reduivy__Parent_Score_Detail__c = isd_lv1_parentBefore.Id,
            reduivy__Weighted_Score__c = 10,
            reduivy__Weight__c = 100,
            reduivy__Status__c = ISD_Helper.STATUS_ACTIVE
        );
        reduivy__Individual_Score_Detail__c isdToInsert2 = new reduivy__Individual_Score_Detail__c(
            reduivy__Individual_Score__c = parentIsc.Id,
            reduivy__Parent_Score_Detail__c = isd_lv1_parentBefore.Id,
            reduivy__Weighted_Score__c = 5,
            reduivy__Weight__c = 100,
            reduivy__Status__c = ISD_Helper.STATUS_ACTIVE
        );

        System.Assert.isTrue(isNullor0(isd_lv1_parentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the parent Individual Score Detail should be 0 before inserting! Actual: ' + isd_lv1_parentBefore.reduivy__Weighted_Score__c);

        System.runAs(ADMIN_USER) {
            insert new List<reduivy__Individual_Score_Detail__c> {isdToInsert1, isdToInsert2};
        }

        reduivy__Individual_Score_Detail__c isd_lv1_parentAfter = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdToInsert1.reduivy__Weighted_Score__c, 'Weighted Score of the child Individual Score Detail should be 10 after inserted!');
        System.Assert.areEqual(5, isdToInsert2.reduivy__Weighted_Score__c, 'Weighted Score of the child Individual Score Detail should be 5 after inserted!');
        System.Assert.areEqual(15, isd_lv1_parentAfter.reduivy__Weighted_Score__c, 'Weighted Score of the parent Individual Score Detail should be 15 after inserted!');

        Test.stopTest();
    }

    /**
     * @description Test as admin for inserting weighted score of 1 lv2 children score detail and 1 lv3 children score detail
     */
	@IsTest
    static void testForInsert_1WeightedScoreLv2_1WeightedScoreLv3_AsAdmin(){
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        Test.startTest();

        reduivy__Individual_Score__c parentIsc = queryIsc();
        reduivy__Individual_Score_Detail__c isd_lv1_parentBefore = queryIsd(ISD_LV1_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isd_lv2_parentBefore = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdToInsert1 = new reduivy__Individual_Score_Detail__c(
            reduivy__Individual_Score__c = parentIsc.Id,
            reduivy__Parent_Score_Detail__c = isd_lv1_parentBefore.Id,
            reduivy__Weighted_Score__c = 10,
            reduivy__Weight__c = 100,
            reduivy__Status__c = ISD_Helper.STATUS_ACTIVE
        );
        reduivy__Individual_Score_Detail__c isdToInsert2 = new reduivy__Individual_Score_Detail__c(
            reduivy__Individual_Score__c = parentIsc.Id,
            reduivy__Parent_Score_Detail__c = isd_lv2_parentBefore.Id,
            reduivy__Weighted_Score__c = 5,
            reduivy__Weight__c = 100,
            reduivy__Status__c = ISD_Helper.STATUS_ACTIVE
        );

        System.Assert.isTrue(isNullor0(isd_lv1_parentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the parent Individual Score Detail should be 0 before inserting! Actual: ' + isd_lv1_parentBefore.reduivy__Weighted_Score__c);

        System.runAs(ADMIN_USER) {
            insert new List<reduivy__Individual_Score_Detail__c> {isdToInsert1, isdToInsert2};
        }

        reduivy__Individual_Score_Detail__c isd_lv1_parentAfter = queryIsd(ISD_LV1_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isd_lv2_parentAfter = queryIsd(ISD_LV2_PARENT_SRC);
        System.Assert.areEqual(10, isdToInsert1.reduivy__Weighted_Score__c, 'Weighted Score of the child Individual Score Detail should be 10 after inserted!');
        System.Assert.areEqual(5, isdToInsert2.reduivy__Weighted_Score__c, 'Weighted Score of the child Individual Score Detail should be 5 after inserted!');
        System.Assert.areEqual(15, isd_lv1_parentAfter.reduivy__Weighted_Score__c, 'Weighted Score of the parent Individual Score Detail should be 15 after inserted!');
        System.Assert.areEqual(5, isd_lv2_parentAfter.reduivy__Weighted_Score__c, 'Weighted Score of the parent Individual Score Detail should be 15 after inserted!');

        Test.stopTest();
    }

    /**
     * @description Test as admin for bulk inserting weighted score of 1 lv2 children score details
     */
    @IsTest
    static void testForBulkInsert_AsAdmin() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        
        Integer iscListSize = 50;
        User ADMIN_USER = testFactory.getReduAdminUser();
        Test.startTest();

        reduivy__Study_Scoring_Config__c scf = queryScf();

        REDU_TriggerController.muteTriggers(new Set<String>{'ISC_IdvScoreDetailGeneration_EXE', 'ISD_LinkRequirement_EXE'});
        //create 50 individual score
        List<reduivy__Individual_Score__c> iscList = new List<reduivy__Individual_Score__c>();
        for(Integer i = 1; i <= iscListSize; i++) {
            iscList.add(new reduivy__Individual_Score__c(
                reduivy__Study_Scoring_Config__c = scf.Id,
                Name = 'ISC ' + i,
                reduivy__Sample_Record_Code__c = 'BULK',
                reduivy__Status__c = ISC_Helper.STATUS_ACTIVE
            ));
        }

        insert iscList;

        //create 50 * 2 parent individual score details

        List<reduivy__Individual_Score_Detail__c> parentIsdList = new List<reduivy__Individual_Score_Detail__c>();

        for(reduivy__Individual_Score__c isc : iscList) {
            for(Integer i = 1; i <= 2; i++) {
                parentIsdList.add(new reduivy__Individual_Score_Detail__c(
                    reduivy__Individual_Score__c = isc.Id,
                    Name = 'Parent Isd ' + i,
                    reduivy__Weight__c = 100,
                    reduivy__Status__c = ISD_Helper.STATUS_ACTIVE
                ));
            }
        }
        insert parentIsdList;

        List<reduivy__Individual_Score_Detail__c> childIsdList = new List<reduivy__Individual_Score_Detail__c>();

        //create children isd list
        for(reduivy__Individual_Score_Detail__c parentIsd : parentIsdList) {
            if(parentIsd.Name.endsWith('1')) {
                childIsdList.add(new reduivy__Individual_Score_Detail__c(
                    Name = parentIsd.Name + '_Child Isd 1',
                    reduivy__Individual_Score__c = parentIsd.reduivy__Individual_Score__c,
                    reduivy__Weight__c = 100,
                    reduivy__Weighted_Score__c = 10,
                    reduivy__Parent_Score_Detail__c = parentIsd.Id,
                    reduivy__Status__c = ISD_Helper.STATUS_ACTIVE
                ));
                childIsdList.add(new reduivy__Individual_Score_Detail__c(
                    Name = parentIsd.Name + '_Child Isd 2',
                    reduivy__Individual_Score__c = parentIsd.reduivy__Individual_Score__c,
                    reduivy__Weight__c = 100,
                    reduivy__Weighted_Score__c = 5,
                    reduivy__Parent_Score_Detail__c = parentIsd.Id,
                    reduivy__Status__c = ISD_Helper.STATUS_ACTIVE
                ));
            } else if (parentIsd.Name.endsWith('2')) {
                childIsdList.add(new reduivy__Individual_Score_Detail__c(
                    Name = parentIsd.Name + '_Child Isd 1',
                    reduivy__Individual_Score__c = parentIsd.reduivy__Individual_Score__c,
                    reduivy__Weight__c = 100,
                    reduivy__Weighted_Score__c = 4,
                    reduivy__Parent_Score_Detail__c = parentIsd.Id,
                    reduivy__Status__c = ISD_Helper.STATUS_ACTIVE
                ));
                childIsdList.add(new reduivy__Individual_Score_Detail__c(
                    Name = parentIsd.Name + '_Child Isd 2',
                    reduivy__Individual_Score__c = parentIsd.reduivy__Individual_Score__c,
                    reduivy__Weight__c = 100,
                    reduivy__Weighted_Score__c = 7,
                    reduivy__Parent_Score_Detail__c = parentIsd.Id,
                    reduivy__Status__c = ISD_Helper.STATUS_ACTIVE
                ));
            }
        }

        System.runAs(ADMIN_USER) {
            insert childIsdList;
        }

        Integer parentIsdSize = 0;
        Integer childIsdSize = 0;

        for(reduivy__Individual_Score_Detail__c parentIsd : [
            SELECT Id, Name, reduivy__Individual_Score__c, reduivy__Weighted_Score__c, (
                SELECT Id, Name, reduivy__Weighted_Score__c
                FROM reduivy__Individual_Score_Details__r
            )
            FROM reduivy__Individual_Score_Detail__c
            WHERE Id IN :parentIsdList
        ]) {

            if(parentIsd.Name.endsWith('1')) {
                for(reduivy__Individual_Score_Detail__c childIsd : parentIsd.reduivy__Individual_Score_Details__r) {
                    System.Assert.areEqual(childIsd.Name.endsWith('1') ? 10 : 5, childIsd.reduivy__Weighted_Score__c, 'Wrong weighted score for this child score detail!');
                    childIsdSize++;
                }
                System.Assert.areEqual(15, parentIsd.reduivy__Weighted_Score__c, 'Wrong weighted score for this parent score detail!');
                System.Assert.areEqual(2, parentIsd.reduivy__Individual_Score_Details__r.size(), 'Wrong child score detail size this parent score detail!');
            }
            else if(parentIsd.Name.endsWith('2')) {
                for(reduivy__Individual_Score_Detail__c childIsd : parentIsd.reduivy__Individual_Score_Details__r) {
                    System.Assert.areEqual(childIsd.Name.endsWith('1') ? 4 : 7, childIsd.reduivy__Weighted_Score__c, 'Wrong weighted score for this child score detail!');
                    childIsdSize++;
                }
                System.Assert.areEqual(11, parentIsd.reduivy__Weighted_Score__c, 'Wrong weighted score for this parent score detail!');
                System.Assert.areEqual(2, parentIsd.reduivy__Individual_Score_Details__r.size(), 'Wrong child score detail size this parent score detail!');
            }
            parentIsdSize++;

        }

        System.Assert.areEqual(100, parentIsdSize, 'Wrong parent score detail size!');
        System.Assert.areEqual(200, childIsdSize, 'Wrong children score detail size!');
        
        Test.stopTest();
    }

    /**
     * @description Test as admin for updating weighted score of 1 lv2 children score details
     */
    @IsTest
    static void testForUpdate_1WeightedScoreLv2_AsAdmin() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();


        reduivy__Individual_Score_Detail__c isdlv2_1Before = queryIsd(ISD_LV2_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_parentBefore = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.isTrue(isNullor0(isdlv2_1Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv1_parentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the parent Individual Score Detail should be 0 before updating! Actual: ' + isdlv1_parentBefore.reduivy__Weighted_Score__c);
        isdlv2_1Before.reduivy__Weighted_Score__c = 10;
        
		System.runAs(ADMIN_USER){
            update isdlv2_1Before;
		}

        
        reduivy__Individual_Score_Detail__c isdlv2_1After = queryIsd(ISD_LV2_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_parentAfter = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdlv2_1After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(10, isdlv1_parentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 10!');

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for updating weighted score of 2 lv2 children score details
     */
    @IsTest
    static void testForUpdate_2WeightedScoreLv2_AsAdmin() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        reduivy__Individual_Score_Detail__c isdlv2_1Before = queryIsd(ISD_LV2_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_2Before = queryIsd(ISD_LV2_2_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_parentBefore = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.isTrue(isNullor0(isdlv2_1Before.reduivy__Weighted_Score__c), 'Weighted Score of the first child Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv2_2Before.reduivy__Weighted_Score__c), 'Weighted Score of the second child Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv1_parentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the parent Individual Score Detail should be 0 before updating! Actual: ' + isdlv1_parentBefore.reduivy__Weighted_Score__c);
        isdlv2_1Before.reduivy__Weighted_Score__c = 10;
        isdlv2_2Before.reduivy__Weighted_Score__c = 5;
        
		System.runAs(ADMIN_USER){
            update new List<reduivy__Individual_Score_Detail__c> {isdlv2_1Before, isdlv2_2Before};
		}

        
        reduivy__Individual_Score_Detail__c isdlv2_1After = queryIsd(ISD_LV2_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_2After = queryIsd(ISD_LV2_2_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_parentAfter = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdlv2_1After.reduivy__Weighted_Score__c, 'The weighted score of the first child Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(5, isdlv2_2After.reduivy__Weighted_Score__c, 'The weighted score of the second child Individual Score Detail should be updated to 5!');
        System.Assert.areEqual(15, isdlv1_parentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15!');

        Test.stopTest();
		
    }
    
	
    /**
     * @description Test as admin for updating weighted score of 1 lv3 children score details
     */
    @IsTest
    static void testForUpdate_1WeightedScoreLv3_AsAdmin() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();


        reduivy__Individual_Score_Detail__c isdlv3_1Before = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentBefore = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentBefore = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.isTrue(isNullor0(isdlv3_1Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv3_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv2_parentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the parent Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_parentBefore.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv1_grandparentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the grandparent Individual Score Detail should be 0 before updating! Actual: ' + isdlv1_grandparentBefore.reduivy__Weighted_Score__c);
        isdlv3_1Before.reduivy__Weighted_Score__c = 10;
        
		System.runAs(ADMIN_USER){
            update isdlv3_1Before;
		}

        
        reduivy__Individual_Score_Detail__c isdlv3_1After = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentAfter = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentAfter = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdlv3_1After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(10, isdlv2_parentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(10, isdlv1_grandparentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 10!');

        Test.stopTest();
		
    }

	
    /**
     * @description Test as admin for updating weighted score of 2 lv3 children score details
     */
    @IsTest
    static void testForUpdate_2WeightedScoreLv3_AsAdmin() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();


        reduivy__Individual_Score_Detail__c isdlv3_1Before = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv3_2Before = queryIsd(ISD_LV3_2_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentBefore = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentBefore = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.isTrue(isNullor0(isdlv3_1Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv3_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv3_2Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv3_2Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv2_parentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the parent Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_parentBefore.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv1_grandparentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the grandparent Individual Score Detail should be 0 before updating! Actual: ' + isdlv1_grandparentBefore.reduivy__Weighted_Score__c);
        isdlv3_1Before.reduivy__Weighted_Score__c = 10;
        isdlv3_2Before.reduivy__Weighted_Score__c = 5;
        
		System.runAs(ADMIN_USER){
            update new List<reduivy__Individual_Score_Detail__c> {isdlv3_1Before, isdlv3_2Before};
		}

        
        reduivy__Individual_Score_Detail__c isdlv3_1After = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv3_2After = queryIsd(ISD_LV3_2_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentAfter = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentAfter = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdlv3_1After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(5, isdlv3_2After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 5!');
        System.Assert.areEqual(15, isdlv2_parentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15!');
        System.Assert.areEqual(15, isdlv1_grandparentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15!');

        Test.stopTest();
		
    }
    
    /**
     * @description Test as admin for updating weighted score of 1 lv3 children score details and 1 lv2 children score details
     */
    @IsTest
    static void testForUpdate_1WeightedScoreLv3_1WeightedScoreLv2_AsAdmin() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        reduivy__Individual_Score_Detail__c isdlv3_1Before = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentBefore = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_1Before = queryIsd(ISD_LV2_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentBefore = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.isTrue(isNullor0(isdlv3_1Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv3_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv2_parentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the parent Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_parentBefore.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv2_1Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv1_grandparentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the grandparent Individual Score Detail should be 0 before updating! Actual: ' + isdlv1_grandparentBefore.reduivy__Weighted_Score__c);
        isdlv3_1Before.reduivy__Weighted_Score__c = 10;
        isdlv2_1Before.reduivy__Weighted_Score__c = 5;
        
		System.runAs(ADMIN_USER){
            update new List<reduivy__Individual_Score_Detail__c> {isdlv3_1Before, isdlv2_1Before};
		}

        reduivy__Individual_Score_Detail__c isdlv3_1After = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentAfter = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_1After = queryIsd(ISD_LV2_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentAfter = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdlv3_1After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(10, isdlv2_parentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15!');
        System.Assert.areEqual(5, isdlv2_1After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 5!');
        System.Assert.areEqual(15, isdlv1_grandparentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as admin for updating weighted score of 2 lv3 children score details, rollup parent exceeded max score
     */
    @IsTest
    static void testForUpdate_2WeightedScoreLv3_ParentMax_AsAdmin() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        reduivy__Individual_Score_Detail__c isdlv3_1Before = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv3_2Before = queryIsd(ISD_LV3_2_SRC);
        reduivy__Individual_Score_Detail__c isdlv3_3Before = queryIsd(ISD_LV3_3_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentBefore = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentBefore = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.isTrue(isNullor0(isdlv3_1Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv3_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv3_2Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv3_2Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv3_3Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv3_3Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv2_parentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the parent Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_parentBefore.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv1_grandparentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the grandparent Individual Score Detail should be 0 before updating! Actual: ' + isdlv1_grandparentBefore.reduivy__Weighted_Score__c);
        isdlv3_1Before.reduivy__Weighted_Score__c = 10;
        isdlv3_2Before.reduivy__Weighted_Score__c = 5;
        isdlv3_3Before.reduivy__Weighted_Score__c = 2;
        
		System.runAs(ADMIN_USER){
            update new List<reduivy__Individual_Score_Detail__c> {isdlv3_1Before, isdlv3_2Before, isdlv3_3Before};
		}

        
        reduivy__Individual_Score_Detail__c isdlv3_1After = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv3_2After = queryIsd(ISD_LV3_2_SRC);
        reduivy__Individual_Score_Detail__c isdlv3_3After = queryIsd(ISD_LV3_3_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentAfter = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentAfter = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdlv3_1After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(5, isdlv3_2After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 5!');
        System.Assert.areEqual(2, isdlv3_3After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 2!');
        System.Assert.areNotEqual(17, isdlv2_parentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should not be 17!');
        System.Assert.areEqual(15, isdlv2_parentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15 instead of 17!');
        System.Assert.areEqual(15, isdlv1_grandparentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15!');

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for updating parent score detail of score details
     */
    @IsTest
    static void testForUpdate_ChangeParentScoreDetail_AsAdmin() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        
        
        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        reduivy__Individual_Score_Detail__c isdlv3_1Before = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentBefore = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_1Before = queryIsd(ISD_LV2_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentBefore = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.isTrue(isNullor0(isdlv3_1Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv3_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv2_parentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the parent Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_parentBefore.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv2_1Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv1_grandparentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the grandparent Individual Score Detail should be 0 before updating! Actual: ' + isdlv1_grandparentBefore.reduivy__Weighted_Score__c);
        isdlv3_1Before.reduivy__Weighted_Score__c = 10;
        isdlv2_1Before.reduivy__Weighted_Score__c = 5;
        
        update new List<reduivy__Individual_Score_Detail__c> {isdlv3_1Before, isdlv2_1Before};
		
        reduivy__Individual_Score_Detail__c isdlv3_1After = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentAfter = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_1After = queryIsd(ISD_LV2_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentAfter = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdlv3_1After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(10, isdlv2_parentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(5, isdlv2_1After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 5!');
        System.Assert.areEqual(15, isdlv1_grandparentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15!');

        isdlv3_1After.reduivy__Parent_Score_Detail__c = isdlv1_grandparentAfter.Id;
        isdlv2_1After.reduivy__Parent_Score_Detail__c = isdlv2_parentAfter.Id;

		System.runAs(ADMIN_USER){
            update new List<reduivy__Individual_Score_Detail__c> {isdlv3_1After, isdlv2_1After};
		}

        reduivy__Individual_Score_Detail__c isdlv3_1AfterUpdate = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentAfterUpdate = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_1AfterUpdate = queryIsd(ISD_LV2_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentAfterUpdate = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdlv3_1AfterUpdate.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(5, isdlv2_parentAfterUpdate.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 5!');
        System.Assert.areEqual(5, isdlv2_1AfterUpdate.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 5!');
        System.Assert.areEqual(15, isdlv1_grandparentAfterUpdate.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15!');

        Test.stopTest();
    }
    
    /**
     * @description Test as admin for bulk updating weighted score of 2 lv3 children score details
     */
    @IsTest
    static void testForBulkUpdate_AsAdmin() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        
        Integer iscListSize = 50;
        User ADMIN_USER = testFactory.getReduAdminUser();
        Test.startTest();

        reduivy__Study_Scoring_Config__c scf = queryScf();
        REDU_TriggerController.muteTriggers(new Set<String>{'ISC_IdvScoreDetailGeneration_EXE', 'ISD_LinkRequirement_EXE'});

        //create 50 individual score
        List<reduivy__Individual_Score__c> iscList = new List<reduivy__Individual_Score__c>();
        for(Integer i = 1; i <= iscListSize; i++) {
            iscList.add(new reduivy__Individual_Score__c(
                reduivy__Study_Scoring_Config__c = scf.Id,
                Name = 'ISC ' + i,
                reduivy__Sample_Record_Code__c = 'BULK',
                reduivy__Status__c = ISC_Helper.STATUS_ACTIVE
            ));
        }

        insert iscList;

        //create 50 * 2 parent individual score details

        List<reduivy__Individual_Score_Detail__c> parentIsdList = new List<reduivy__Individual_Score_Detail__c>();

        for(reduivy__Individual_Score__c isc : iscList) {
            for(Integer i = 1; i <= 2; i++) {
                parentIsdList.add(new reduivy__Individual_Score_Detail__c(
                    reduivy__Individual_Score__c = isc.Id,
                    Name = 'Parent Isd ' + i,
                    reduivy__Weight__c = 100,
                    reduivy__Status__c = ISD_Helper.STATUS_ACTIVE
                ));
            }
        }
        insert parentIsdList;

        List<reduivy__Individual_Score_Detail__c> childIsdList = new List<reduivy__Individual_Score_Detail__c>();

        //create children isd list
        for(reduivy__Individual_Score_Detail__c parentIsd : parentIsdList) {
            if(parentIsd.Name.endsWith('1')) {
                childIsdList.add(new reduivy__Individual_Score_Detail__c(
                    Name = parentIsd.Name + '_Child Isd 1',
                    reduivy__Individual_Score__c = parentIsd.reduivy__Individual_Score__c,
                    reduivy__Weight__c = 100,
                    reduivy__Parent_Score_Detail__c = parentIsd.Id,
                    reduivy__Status__c = ISD_Helper.STATUS_ACTIVE
                ));
                childIsdList.add(new reduivy__Individual_Score_Detail__c(
                    Name = parentIsd.Name + '_Child Isd 2',
                    reduivy__Individual_Score__c = parentIsd.reduivy__Individual_Score__c,
                    reduivy__Weight__c = 100,
                    reduivy__Parent_Score_Detail__c = parentIsd.Id,
                    reduivy__Status__c = ISD_Helper.STATUS_ACTIVE
                ));
            } else if (parentIsd.Name.endsWith('2')) {
                childIsdList.add(new reduivy__Individual_Score_Detail__c(
                    Name = parentIsd.Name + '_Child Isd 1',
                    reduivy__Individual_Score__c = parentIsd.reduivy__Individual_Score__c,
                    reduivy__Weight__c = 100,
                    reduivy__Parent_Score_Detail__c = parentIsd.Id,
                    reduivy__Status__c = ISD_Helper.STATUS_ACTIVE
                ));
                childIsdList.add(new reduivy__Individual_Score_Detail__c(
                    Name = parentIsd.Name + '_Child Isd 2',
                    reduivy__Individual_Score__c = parentIsd.reduivy__Individual_Score__c,
                    reduivy__Weight__c = 100,
                    reduivy__Parent_Score_Detail__c = parentIsd.Id,
                    reduivy__Status__c = ISD_Helper.STATUS_ACTIVE
                ));
            }
        }

        insert childIsdList;

        for(reduivy__Individual_Score_Detail__c childIsd : childIsdList) {
            if(childIsd.Name.startsWith('Parent Isd 1')) {
                childIsd.reduivy__Weighted_Score__c = childIsd.Name.endsWith('1') ? 10 : 5;
            } else {
                childIsd.reduivy__Weighted_Score__c = childIsd.Name.endsWith('1') ? 4 : 7;
            }
        }

        System.runAs(ADMIN_USER) {
            update childIsdList;
        }

        Integer parentIsdSize = 0;
        Integer childIsdSize = 0;

        for(reduivy__Individual_Score_Detail__c parentIsd : [
            SELECT Id, Name, reduivy__Individual_Score__c, reduivy__Weighted_Score__c, (
                SELECT Id, Name, reduivy__Weighted_Score__c
                FROM reduivy__Individual_Score_Details__r
            )
            FROM reduivy__Individual_Score_Detail__c
            WHERE Id IN :parentIsdList
        ]) {

            if(parentIsd.Name.endsWith('1')) {
                for(reduivy__Individual_Score_Detail__c childIsd : parentIsd.reduivy__Individual_Score_Details__r) {
                    System.Assert.areEqual(childIsd.Name.endsWith('1') ? 10 : 5, childIsd.reduivy__Weighted_Score__c, 'Wrong weighted score for this child score detail!');
                    childIsdSize++;
                }
                System.Assert.areEqual(15, parentIsd.reduivy__Weighted_Score__c, 'Wrong weighted score for this parent score detail!');
                System.Assert.areEqual(2, parentIsd.reduivy__Individual_Score_Details__r.size(), 'Wrong child score detail size this parent score detail!');
            }
            else if(parentIsd.Name.endsWith('2')) {
                for(reduivy__Individual_Score_Detail__c childIsd : parentIsd.reduivy__Individual_Score_Details__r) {
                    System.Assert.areEqual(childIsd.Name.endsWith('1') ? 4 : 7, childIsd.reduivy__Weighted_Score__c, 'Wrong weighted score for this child score detail!');
                    childIsdSize++;
                }
                System.Assert.areEqual(11, parentIsd.reduivy__Weighted_Score__c, 'Wrong weighted score for this parent score detail!');
                System.Assert.areEqual(2, parentIsd.reduivy__Individual_Score_Details__r.size(), 'Wrong child score detail size this parent score detail!');
            }
            parentIsdSize++;

        }

        System.Assert.areEqual(100, parentIsdSize, 'Wrong parent score detail size!');
        System.Assert.areEqual(200, childIsdSize, 'Wrong children score detail size!');
        
        Test.stopTest();
    }
    
    /**
     * @description Test as admin for deleting and undeleting weighted score of 1 lv2 children score details
     */
    @IsTest
    static void testForDeleteUndelete_1WeightedScoreLv2_AsAdmin() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();


        reduivy__Individual_Score_Detail__c isdlv2_1Before = queryIsd(ISD_LV2_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_parentBefore = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.isTrue(isNullor0(isdlv2_1Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv1_parentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the parent Individual Score Detail should be 0 before updating! Actual: ' + isdlv1_parentBefore.reduivy__Weighted_Score__c);
        isdlv2_1Before.reduivy__Weighted_Score__c = 10;
        
		System.runAs(ADMIN_USER){
            update isdlv2_1Before;
		}

        reduivy__Individual_Score_Detail__c isdlv2_1After = queryIsd(ISD_LV2_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_parentAfter = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdlv2_1After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(10, isdlv1_parentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 10!');

		System.runAs(ADMIN_USER){
            delete isdlv2_1After;
        }

        reduivy__Individual_Score_Detail__c isdlv1_parentAfterDelete = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(0, isdlv1_parentAfterDelete.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 0!');

		System.runAs(ADMIN_USER){
            undelete isdlv2_1After;
        }

        reduivy__Individual_Score_Detail__c isdlv1_parentAfterUndelete = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdlv1_parentAfterUndelete.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 10!');
        

        Test.stopTest();
		
    }

    /**
     * @description Test as admin for deleting and undeleting weighted score of 2 lv2 children score details
     */
    @IsTest
    static void testForDeleteUndelete_2WeightedScoreLv2_AsAdmin() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        reduivy__Individual_Score_Detail__c isdlv2_1Before = queryIsd(ISD_LV2_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_2Before = queryIsd(ISD_LV2_2_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_parentBefore = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.isTrue(isNullor0(isdlv2_1Before.reduivy__Weighted_Score__c), 'Weighted Score of the first child Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv2_2Before.reduivy__Weighted_Score__c), 'Weighted Score of the second child Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv1_parentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the parent Individual Score Detail should be 0 before updating! Actual: ' + isdlv1_parentBefore.reduivy__Weighted_Score__c);
        isdlv2_1Before.reduivy__Weighted_Score__c = 10;
        isdlv2_2Before.reduivy__Weighted_Score__c = 5;
        
        update new List<reduivy__Individual_Score_Detail__c> {isdlv2_1Before, isdlv2_2Before};

        reduivy__Individual_Score_Detail__c isdlv2_1After = queryIsd(ISD_LV2_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_2After = queryIsd(ISD_LV2_2_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_parentAfter = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdlv2_1After.reduivy__Weighted_Score__c, 'The weighted score of the first child Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(5, isdlv2_2After.reduivy__Weighted_Score__c, 'The weighted score of the second child Individual Score Detail should be updated to 5!');
        System.Assert.areEqual(15, isdlv1_parentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15!');

		System.runAs(ADMIN_USER){
            delete isdlv2_1After;
        }
        
        reduivy__Individual_Score_Detail__c isdlv1_parentAfterDelete = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(5, isdlv1_parentAfterDelete.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 5!');

        System.runAs(ADMIN_USER) {
            undelete isdlv2_1After;
        }

        reduivy__Individual_Score_Detail__c isdlv1_parentAfterUndelete = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(15, isdlv1_parentAfterUndelete.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as admin for deleting and undeleting weighted score of 1 lv3 children score details
     */
    @IsTest
    static void testForDeleteUndelete_1WeightedScoreLv3_AsAdmin() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        reduivy__Individual_Score_Detail__c isdlv3_1Before = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentBefore = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentBefore = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.isTrue(isNullor0(isdlv3_1Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv3_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv2_parentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the parent Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_parentBefore.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv1_grandparentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the grandparent Individual Score Detail should be 0 before updating! Actual: ' + isdlv1_grandparentBefore.reduivy__Weighted_Score__c);
        isdlv3_1Before.reduivy__Weighted_Score__c = 10;
        
		System.runAs(ADMIN_USER){
            update isdlv3_1Before;
		}
        
        reduivy__Individual_Score_Detail__c isdlv3_1After = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentAfter = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentAfter = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdlv3_1After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(10, isdlv2_parentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(10, isdlv1_grandparentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 10!');

        
		System.runAs(ADMIN_USER){
            delete isdlv3_1After;
        }

        reduivy__Individual_Score_Detail__c isdlv2_parentAfterDelete = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentAfterDelete = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(0, isdlv2_parentAfterDelete.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 0!');
        System.Assert.areEqual(0, isdlv1_grandparentAfterDelete.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 0!');

		System.runAs(ADMIN_USER){
            undelete isdlv3_1After;
        }

        reduivy__Individual_Score_Detail__c isdlv2_parentAfterUndelete = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentAfterUndelete = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdlv2_parentAfterUndelete.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(10, isdlv1_grandparentAfterUndelete.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 10!');

        Test.stopTest();
    }

    /**
     * @description Test as admin for deleting and undeleting weighted score of 2 lv3 children score details
     */
    @IsTest
    static void testForDeleteUndelete_2WeightedScoreLv3_AsAdmin() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();


        reduivy__Individual_Score_Detail__c isdlv3_1Before = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv3_2Before = queryIsd(ISD_LV3_2_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentBefore = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentBefore = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.isTrue(isNullor0(isdlv3_1Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv3_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv3_2Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv3_2Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv2_parentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the parent Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_parentBefore.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv1_grandparentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the grandparent Individual Score Detail should be 0 before updating! Actual: ' + isdlv1_grandparentBefore.reduivy__Weighted_Score__c);
        isdlv3_1Before.reduivy__Weighted_Score__c = 10;
        isdlv3_2Before.reduivy__Weighted_Score__c = 5;
        
		System.runAs(ADMIN_USER){
            update new List<reduivy__Individual_Score_Detail__c> {isdlv3_1Before, isdlv3_2Before};
		}

        
        reduivy__Individual_Score_Detail__c isdlv3_1After = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv3_2After = queryIsd(ISD_LV3_2_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentAfter = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentAfter = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdlv3_1After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(5, isdlv3_2After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 5!');
        System.Assert.areEqual(15, isdlv2_parentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15!');
        System.Assert.areEqual(15, isdlv1_grandparentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15!');

        System.runAs(ADMIN_USER) {
            delete isdlv3_1After;
        }

        reduivy__Individual_Score_Detail__c isdlv2_parentAfterDelete = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentAfterDelete = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(5, isdlv2_parentAfterDelete.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 5!');
        System.Assert.areEqual(5, isdlv1_grandparentAfterDelete.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 5!');


        System.runAs(ADMIN_USER) {
            undelete isdlv3_1After;
        }

        reduivy__Individual_Score_Detail__c isdlv2_parentAfterUndelete = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentAfterUndelete = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(15, isdlv2_parentAfterUndelete.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15!');
        System.Assert.areEqual(15, isdlv1_grandparentAfterUndelete.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15!');



        Test.stopTest();
		
    }
    
    /**
     * @description Test as admin for deleting and undeleting weighted score of 1 lv2 children score details and 1 lv3 children score details
     */
    @IsTest
    static void testForDeleteUndelete_1WeightedScoreLv3_1WeightedScoreLv2_AsAdmin() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        

        User ADMIN_USER = testFactory.getReduAdminUser();

        Test.startTest();

        reduivy__Individual_Score_Detail__c isdlv3_1Before = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentBefore = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_1Before = queryIsd(ISD_LV2_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentBefore = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.isTrue(isNullor0(isdlv3_1Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv3_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv2_parentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the parent Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_parentBefore.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv2_1Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv1_grandparentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the grandparent Individual Score Detail should be 0 before updating! Actual: ' + isdlv1_grandparentBefore.reduivy__Weighted_Score__c);
        isdlv3_1Before.reduivy__Weighted_Score__c = 10;
        isdlv2_1Before.reduivy__Weighted_Score__c = 5;
        
		System.runAs(ADMIN_USER){
            update new List<reduivy__Individual_Score_Detail__c> {isdlv3_1Before, isdlv2_1Before};
		}

        reduivy__Individual_Score_Detail__c isdlv3_1After = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentAfter = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_1After = queryIsd(ISD_LV2_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentAfter = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdlv3_1After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(10, isdlv2_parentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(5, isdlv2_1After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 5!');
        System.Assert.areEqual(15, isdlv1_grandparentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15!');

		System.runAs(ADMIN_USER){
            delete isdlv3_1After;
		}
        
        reduivy__Individual_Score_Detail__c isdlv2_parentAfterDelete = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentAfterDelete = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(0, isdlv2_parentAfterDelete.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 0!');
        System.Assert.areEqual(5, isdlv1_grandparentAfterDelete.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 5!');

		System.runAs(ADMIN_USER){
            undelete isdlv3_1After;
		}
        
        reduivy__Individual_Score_Detail__c isdlv2_parentAfterUndelete = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentAfterUndelete = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdlv2_parentAfterUndelete.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(15, isdlv1_grandparentAfterUndelete.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15!');


        Test.stopTest();
		
    }

    
    /**
     * @description Test as admin for bulk deleting and undeleting weighted score of lv2 children score details
     */
    @IsTest
    static void testForBulkDeleteUndelete_AsAdmin() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        
        Integer iscListSize = 50;
        User ADMIN_USER = testFactory.getReduAdminUser();
        Test.startTest();

        reduivy__Study_Scoring_Config__c scf = queryScf();
        REDU_TriggerController.muteTriggers(new Set<String>{'ISC_IdvScoreDetailGeneration_EXE', 'ISD_LinkRequirement_EXE'});

        //create 50 individual score
        List<reduivy__Individual_Score__c> iscList = new List<reduivy__Individual_Score__c>();
        for(Integer i = 1; i <= iscListSize; i++) {
            iscList.add(new reduivy__Individual_Score__c(
                reduivy__Study_Scoring_Config__c = scf.Id,
                Name = 'ISC ' + i,
                reduivy__Sample_Record_Code__c = 'BULK',
                reduivy__Status__c = ISC_Helper.STATUS_ACTIVE
            ));
        }

        insert iscList;

        //create 50 * 2 parent individual score details

        List<reduivy__Individual_Score_Detail__c> parentIsdList = new List<reduivy__Individual_Score_Detail__c>();

        for(reduivy__Individual_Score__c isc : iscList) {
            for(Integer i = 1; i <= 2; i++) {
                parentIsdList.add(new reduivy__Individual_Score_Detail__c(
                    reduivy__Individual_Score__c = isc.Id,
                    Name = 'Parent Isd ' + i,
                    reduivy__Weight__c = 100,
                    reduivy__Status__c = ISD_Helper.STATUS_ACTIVE
                ));
            }
        }
        insert parentIsdList;

        List<reduivy__Individual_Score_Detail__c> childIsdList = new List<reduivy__Individual_Score_Detail__c>();

        //create children isd list
        for(reduivy__Individual_Score_Detail__c parentIsd : parentIsdList) {
            if(parentIsd.Name.endsWith('1')) {
                childIsdList.add(new reduivy__Individual_Score_Detail__c(
                    Name = parentIsd.Name + '_Child Isd 1',
                    reduivy__Individual_Score__c = parentIsd.reduivy__Individual_Score__c,
                    reduivy__Weight__c = 100,
                    reduivy__Parent_Score_Detail__c = parentIsd.Id,
                    reduivy__Status__c = ISD_Helper.STATUS_ACTIVE
                ));
                childIsdList.add(new reduivy__Individual_Score_Detail__c(
                    Name = parentIsd.Name + '_Child Isd 2',
                    reduivy__Individual_Score__c = parentIsd.reduivy__Individual_Score__c,
                    reduivy__Weight__c = 100,
                    reduivy__Parent_Score_Detail__c = parentIsd.Id,
                    reduivy__Status__c = ISD_Helper.STATUS_ACTIVE
                ));
            } else if (parentIsd.Name.endsWith('2')) {
                childIsdList.add(new reduivy__Individual_Score_Detail__c(
                    Name = parentIsd.Name + '_Child Isd 1',
                    reduivy__Individual_Score__c = parentIsd.reduivy__Individual_Score__c,
                    reduivy__Weight__c = 100,
                    reduivy__Parent_Score_Detail__c = parentIsd.Id,
                    reduivy__Status__c = ISD_Helper.STATUS_ACTIVE
                ));
                childIsdList.add(new reduivy__Individual_Score_Detail__c(
                    Name = parentIsd.Name + '_Child Isd 2',
                    reduivy__Individual_Score__c = parentIsd.reduivy__Individual_Score__c,
                    reduivy__Weight__c = 100,
                    reduivy__Parent_Score_Detail__c = parentIsd.Id,
                    reduivy__Status__c = ISD_Helper.STATUS_ACTIVE
                ));
            }
        }

        insert childIsdList;

        for(reduivy__Individual_Score_Detail__c childIsd : childIsdList) {
            if(childIsd.Name.startsWith('Parent Isd 1')) {
                childIsd.reduivy__Weighted_Score__c = childIsd.Name.endsWith('1') ? 10 : 5;
            } else {
                childIsd.reduivy__Weighted_Score__c = childIsd.Name.endsWith('1') ? 4 : 7;
            }
        }

        update childIsdList;
        

        Integer parentIsdSize = 0;
        Integer childIsdSize = 0;

        for(reduivy__Individual_Score_Detail__c parentIsd : [
            SELECT Id, Name, reduivy__Individual_Score__c, reduivy__Weighted_Score__c, (
                SELECT Id, Name, reduivy__Weighted_Score__c
                FROM reduivy__Individual_Score_Details__r
            )
            FROM reduivy__Individual_Score_Detail__c
            WHERE Id IN :parentIsdList
        ]) {

            if(parentIsd.Name.endsWith('1')) {
                for(reduivy__Individual_Score_Detail__c childIsd : parentIsd.reduivy__Individual_Score_Details__r) {
                    System.Assert.areEqual(childIsd.Name.endsWith('1') ? 10 : 5, childIsd.reduivy__Weighted_Score__c, 'Wrong weighted score for this child score detail!');
                    childIsdSize++;
                }
                System.Assert.areEqual(15, parentIsd.reduivy__Weighted_Score__c, 'Wrong weighted score for this parent score detail!');
                System.Assert.areEqual(2, parentIsd.reduivy__Individual_Score_Details__r.size(), 'Wrong child score detail size this parent score detail!');
            }
            else if(parentIsd.Name.endsWith('2')) {
                for(reduivy__Individual_Score_Detail__c childIsd : parentIsd.reduivy__Individual_Score_Details__r) {
                    System.Assert.areEqual(childIsd.Name.endsWith('1') ? 4 : 7, childIsd.reduivy__Weighted_Score__c, 'Wrong weighted score for this child score detail!');
                    childIsdSize++;
                }
                System.Assert.areEqual(11, parentIsd.reduivy__Weighted_Score__c, 'Wrong weighted score for this parent score detail!');
                System.Assert.areEqual(2, parentIsd.reduivy__Individual_Score_Details__r.size(), 'Wrong child score detail size this parent score detail!');
            }
            parentIsdSize++;

        }

        System.Assert.areEqual(100, parentIsdSize, 'Wrong parent score detail size!');
        System.Assert.areEqual(200, childIsdSize, 'Wrong children score detail size!');

        System.runAs(ADMIN_USER) {
            delete childIsdList;
        }

        parentIsdSize = 0;
        childIsdSize = 0;

        for(reduivy__Individual_Score_Detail__c parentIsd : [
            SELECT Id, Name, reduivy__Individual_Score__c, reduivy__Weighted_Score__c, (
                SELECT Id, Name, reduivy__Weighted_Score__c
                FROM reduivy__Individual_Score_Details__r
            )
            FROM reduivy__Individual_Score_Detail__c
            WHERE Id IN :parentIsdList
        ]) {
            for(reduivy__Individual_Score_Detail__c childIsd : parentIsd.reduivy__Individual_Score_Details__r) {
                childIsdSize++;
            }
            System.Assert.areEqual(0, parentIsd.reduivy__Weighted_Score__c, 'Weighted Score should be updated to 0!');
            parentIsdSize++;
        }

        System.Assert.areEqual(100, parentIsdSize, 'Wrong parent score detail size!');
        System.Assert.areEqual(0, childIsdSize, 'Wrong children score detail size!');

        
        System.runAs(ADMIN_USER) {
            undelete childIsdList;
        }

        parentIsdSize = 0;
        childIsdSize = 0;

        for(reduivy__Individual_Score_Detail__c parentIsd : [
            SELECT Id, Name, reduivy__Individual_Score__c, reduivy__Weighted_Score__c, (
                SELECT Id, Name, reduivy__Weighted_Score__c
                FROM reduivy__Individual_Score_Details__r
            )
            FROM reduivy__Individual_Score_Detail__c
            WHERE Id IN :parentIsdList
        ]) {

            if(parentIsd.Name.endsWith('1')) {
                for(reduivy__Individual_Score_Detail__c childIsd : parentIsd.reduivy__Individual_Score_Details__r) {
                    System.Assert.areEqual(childIsd.Name.endsWith('1') ? 10 : 5, childIsd.reduivy__Weighted_Score__c, 'Wrong weighted score for this child score detail!');
                    childIsdSize++;
                }
                System.Assert.areEqual(15, parentIsd.reduivy__Weighted_Score__c, 'Wrong weighted score for this parent score detail!');
                System.Assert.areEqual(2, parentIsd.reduivy__Individual_Score_Details__r.size(), 'Wrong child score detail size this parent score detail!');
            }
            else if(parentIsd.Name.endsWith('2')) {
                for(reduivy__Individual_Score_Detail__c childIsd : parentIsd.reduivy__Individual_Score_Details__r) {
                    System.Assert.areEqual(childIsd.Name.endsWith('1') ? 4 : 7, childIsd.reduivy__Weighted_Score__c, 'Wrong weighted score for this child score detail!');
                    childIsdSize++;
                }
                System.Assert.areEqual(11, parentIsd.reduivy__Weighted_Score__c, 'Wrong weighted score for this parent score detail!');
                System.Assert.areEqual(2, parentIsd.reduivy__Individual_Score_Details__r.size(), 'Wrong child score detail size this parent score detail!');
            }
            parentIsdSize++;

        }

        System.Assert.areEqual(100, parentIsdSize, 'Wrong parent score detail size!');
        System.Assert.areEqual(200, childIsdSize, 'Wrong children score detail size!');
        

        Test.stopTest();
    }
    
    
    /**
     * @description Test as faculty for inserting weighted score of 1 lv2 children score details
     */
	@IsTest
    static void testForInsert_1WeightedScoreLv2_AsFaculty(){
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        Test.startTest();

        reduivy__Individual_Score__c parentIsc = queryIsc();
        reduivy__Individual_Score_Detail__c isd_lv1_parentBefore = queryIsd(ISD_LV1_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdToInsert = new reduivy__Individual_Score_Detail__c(
            reduivy__Individual_Score__c = parentIsc.Id,
            reduivy__Parent_Score_Detail__c = isd_lv1_parentBefore.Id,
            reduivy__Weighted_Score__c = 10,
            reduivy__Weight__c = 100,
            reduivy__Status__c = ISD_Helper.STATUS_ACTIVE
        );

        System.Assert.isTrue(isNullor0(isd_lv1_parentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the parent Individual Score Detail should be 0 before inserting! Actual: ' + isd_lv1_parentBefore.reduivy__Weighted_Score__c);

        System.runAs(FACULTY_USER) {
            insert isdToInsert;
        }

        reduivy__Individual_Score_Detail__c isd_lv1_parentAfter = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdToInsert.reduivy__Weighted_Score__c, 'Weighted Score of the child Individual Score Detail should be 10 after inserted!');
        System.Assert.areEqual(10, isd_lv1_parentAfter.reduivy__Weighted_Score__c, 'Weighted Score of the parent Individual Score Detail should be 10 after inserted!');

        Test.stopTest();
    }

    /**
     * @description Test as faculty for inserting weighted score of 2 lv2 children score details
     */
	@IsTest
    static void testForInsert_2WeightedScoreLv2_AsFaculty(){
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        Test.startTest();

        reduivy__Individual_Score__c parentIsc = queryIsc();
        reduivy__Individual_Score_Detail__c isd_lv1_parentBefore = queryIsd(ISD_LV1_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdToInsert1 = new reduivy__Individual_Score_Detail__c(
            reduivy__Individual_Score__c = parentIsc.Id,
            reduivy__Parent_Score_Detail__c = isd_lv1_parentBefore.Id,
            reduivy__Weighted_Score__c = 10,
            reduivy__Weight__c = 100,
            reduivy__Status__c = ISD_Helper.STATUS_ACTIVE
        );
        reduivy__Individual_Score_Detail__c isdToInsert2 = new reduivy__Individual_Score_Detail__c(
            reduivy__Individual_Score__c = parentIsc.Id,
            reduivy__Parent_Score_Detail__c = isd_lv1_parentBefore.Id,
            reduivy__Weighted_Score__c = 5,
            reduivy__Weight__c = 100,
            reduivy__Status__c = ISD_Helper.STATUS_ACTIVE
        );

        System.Assert.isTrue(isNullor0(isd_lv1_parentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the parent Individual Score Detail should be 0 before inserting! Actual: ' + isd_lv1_parentBefore.reduivy__Weighted_Score__c);

        System.runAs(FACULTY_USER) {
            insert new List<reduivy__Individual_Score_Detail__c> {isdToInsert1, isdToInsert2};
        }

        reduivy__Individual_Score_Detail__c isd_lv1_parentAfter = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdToInsert1.reduivy__Weighted_Score__c, 'Weighted Score of the child Individual Score Detail should be 10 after inserted!');
        System.Assert.areEqual(5, isdToInsert2.reduivy__Weighted_Score__c, 'Weighted Score of the child Individual Score Detail should be 5 after inserted!');
        System.Assert.areEqual(15, isd_lv1_parentAfter.reduivy__Weighted_Score__c, 'Weighted Score of the parent Individual Score Detail should be 15 after inserted!');

        Test.stopTest();
    }

    /**
     * @description Test as faculty for inserting weighted score of 1 lv2 children score detail and 1 lv3 children score detail
     */
	@IsTest
    static void testForInsert_1WeightedScoreLv2_1WeightedScoreLv3_AsFaculty(){
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        
        User FACULTY_USER = testFactory.getReduFacultyUser();
        Test.startTest();

        reduivy__Individual_Score__c parentIsc = queryIsc();
        reduivy__Individual_Score_Detail__c isd_lv1_parentBefore = queryIsd(ISD_LV1_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isd_lv2_parentBefore = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdToInsert1 = new reduivy__Individual_Score_Detail__c(
            reduivy__Individual_Score__c = parentIsc.Id,
            reduivy__Parent_Score_Detail__c = isd_lv1_parentBefore.Id,
            reduivy__Weighted_Score__c = 10,
            reduivy__Weight__c = 100,
            reduivy__Status__c = ISD_Helper.STATUS_ACTIVE
        );
        reduivy__Individual_Score_Detail__c isdToInsert2 = new reduivy__Individual_Score_Detail__c(
            reduivy__Individual_Score__c = parentIsc.Id,
            reduivy__Parent_Score_Detail__c = isd_lv2_parentBefore.Id,
            reduivy__Weighted_Score__c = 5,
            reduivy__Weight__c = 100,
            reduivy__Status__c = ISD_Helper.STATUS_ACTIVE
        );

        System.Assert.isTrue(isNullor0(isd_lv1_parentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the parent Individual Score Detail should be 0 before inserting! Actual: ' + isd_lv1_parentBefore.reduivy__Weighted_Score__c);

        System.runAs(FACULTY_USER) {
            insert new List<reduivy__Individual_Score_Detail__c> {isdToInsert1, isdToInsert2};
        }

        reduivy__Individual_Score_Detail__c isd_lv1_parentAfter = queryIsd(ISD_LV1_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isd_lv2_parentAfter = queryIsd(ISD_LV2_PARENT_SRC);
        System.Assert.areEqual(10, isdToInsert1.reduivy__Weighted_Score__c, 'Weighted Score of the child Individual Score Detail should be 10 after inserted!');
        System.Assert.areEqual(5, isdToInsert2.reduivy__Weighted_Score__c, 'Weighted Score of the child Individual Score Detail should be 5 after inserted!');
        System.Assert.areEqual(15, isd_lv1_parentAfter.reduivy__Weighted_Score__c, 'Weighted Score of the parent Individual Score Detail should be 15 after inserted!');
        System.Assert.areEqual(5, isd_lv2_parentAfter.reduivy__Weighted_Score__c, 'Weighted Score of the parent Individual Score Detail should be 15 after inserted!');

        Test.stopTest();
    }

    /**
     * @description Test as faculty for updating weighted score of 1 lv2 children score details
     */
    @IsTest
    static void testForUpdate_1WeightedScoreLv2_AsFaculty() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();


        reduivy__Individual_Score_Detail__c isdlv2_1Before = queryIsd(ISD_LV2_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_parentBefore = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.isTrue(isNullor0(isdlv2_1Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv1_parentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the parent Individual Score Detail should be 0 before updating! Actual: ' + isdlv1_parentBefore.reduivy__Weighted_Score__c);
        isdlv2_1Before.reduivy__Weighted_Score__c = 10;
        
		System.runAs(FACULTY_USER){
            update isdlv2_1Before;
		}

        
        reduivy__Individual_Score_Detail__c isdlv2_1After = queryIsd(ISD_LV2_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_parentAfter = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdlv2_1After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(10, isdlv1_parentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 10!');

        Test.stopTest();
		
    }

    /**
     * @description Test as faculty for updating weighted score of 2 lv2 children score details
     */
    @IsTest
    static void testForUpdate_2WeightedScoreLv2_AsFaculty() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        reduivy__Individual_Score_Detail__c isdlv2_1Before = queryIsd(ISD_LV2_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_2Before = queryIsd(ISD_LV2_2_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_parentBefore = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.isTrue(isNullor0(isdlv2_1Before.reduivy__Weighted_Score__c), 'Weighted Score of the first child Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv2_2Before.reduivy__Weighted_Score__c), 'Weighted Score of the second child Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv1_parentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the parent Individual Score Detail should be 0 before updating! Actual: ' + isdlv1_parentBefore.reduivy__Weighted_Score__c);
        isdlv2_1Before.reduivy__Weighted_Score__c = 10;
        isdlv2_2Before.reduivy__Weighted_Score__c = 5;
        
		System.runAs(FACULTY_USER){
            update new List<reduivy__Individual_Score_Detail__c> {isdlv2_1Before, isdlv2_2Before};
		}

        
        reduivy__Individual_Score_Detail__c isdlv2_1After = queryIsd(ISD_LV2_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_2After = queryIsd(ISD_LV2_2_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_parentAfter = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdlv2_1After.reduivy__Weighted_Score__c, 'The weighted score of the first child Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(5, isdlv2_2After.reduivy__Weighted_Score__c, 'The weighted score of the second child Individual Score Detail should be updated to 5!');
        System.Assert.areEqual(15, isdlv1_parentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15!');

        Test.stopTest();
		
    }
    
	
    /**
     * @description Test as faculty for updating weighted score of 1 lv3 children score details
     */
    @IsTest
    static void testForUpdate_1WeightedScoreLv3_AsFaculty() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();


        reduivy__Individual_Score_Detail__c isdlv3_1Before = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentBefore = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentBefore = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.isTrue(isNullor0(isdlv3_1Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv3_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv2_parentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the parent Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_parentBefore.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv1_grandparentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the grandparent Individual Score Detail should be 0 before updating! Actual: ' + isdlv1_grandparentBefore.reduivy__Weighted_Score__c);
        isdlv3_1Before.reduivy__Weighted_Score__c = 10;
        
		System.runAs(FACULTY_USER){
            update isdlv3_1Before;
		}

        
        reduivy__Individual_Score_Detail__c isdlv3_1After = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentAfter = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentAfter = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdlv3_1After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(10, isdlv2_parentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(10, isdlv1_grandparentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 10!');

        Test.stopTest();
		
    }

	
    /**
     * @description Test as faculty for updating weighted score of 2 lv3 children score details
     */
    @IsTest
    static void testForUpdate_2WeightedScoreLv3_AsFaculty() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();


        reduivy__Individual_Score_Detail__c isdlv3_1Before = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv3_2Before = queryIsd(ISD_LV3_2_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentBefore = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentBefore = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.isTrue(isNullor0(isdlv3_1Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv3_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv3_2Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv3_2Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv2_parentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the parent Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_parentBefore.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv1_grandparentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the grandparent Individual Score Detail should be 0 before updating! Actual: ' + isdlv1_grandparentBefore.reduivy__Weighted_Score__c);
        isdlv3_1Before.reduivy__Weighted_Score__c = 10;
        isdlv3_2Before.reduivy__Weighted_Score__c = 5;
        
		System.runAs(FACULTY_USER){
            update new List<reduivy__Individual_Score_Detail__c> {isdlv3_1Before, isdlv3_2Before};
		}

        
        reduivy__Individual_Score_Detail__c isdlv3_1After = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv3_2After = queryIsd(ISD_LV3_2_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentAfter = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentAfter = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdlv3_1After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(5, isdlv3_2After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 5!');
        System.Assert.areEqual(15, isdlv2_parentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15!');
        System.Assert.areEqual(15, isdlv1_grandparentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15!');

        Test.stopTest();
		
    }
    
    /**
     * @description Test as faculty for updating weighted score of 1 lv3 children score details and 1 lv2 children score details
     */
    @IsTest
    static void testForUpdate_1WeightedScoreLv3_1WeightedScoreLv2_AsFaculty() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        reduivy__Individual_Score_Detail__c isdlv3_1Before = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentBefore = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_1Before = queryIsd(ISD_LV2_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentBefore = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.isTrue(isNullor0(isdlv3_1Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv3_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv2_parentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the parent Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_parentBefore.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv2_1Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv1_grandparentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the grandparent Individual Score Detail should be 0 before updating! Actual: ' + isdlv1_grandparentBefore.reduivy__Weighted_Score__c);
        isdlv3_1Before.reduivy__Weighted_Score__c = 10;
        isdlv2_1Before.reduivy__Weighted_Score__c = 5;
        
		System.runAs(FACULTY_USER){
            update new List<reduivy__Individual_Score_Detail__c> {isdlv3_1Before, isdlv2_1Before};
		}

        reduivy__Individual_Score_Detail__c isdlv3_1After = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentAfter = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_1After = queryIsd(ISD_LV2_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentAfter = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdlv3_1After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(10, isdlv2_parentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15!');
        System.Assert.areEqual(5, isdlv2_1After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 5!');
        System.Assert.areEqual(15, isdlv1_grandparentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as faculty for updating weighted score of 2 lv3 children score details, rollup parent exceeded max score
     */
    @IsTest
    static void testForUpdate_2WeightedScoreLv3_ParentMax_AsFaculty() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        reduivy__Individual_Score_Detail__c isdlv3_1Before = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv3_2Before = queryIsd(ISD_LV3_2_SRC);
        reduivy__Individual_Score_Detail__c isdlv3_3Before = queryIsd(ISD_LV3_3_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentBefore = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentBefore = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.isTrue(isNullor0(isdlv3_1Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv3_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv3_2Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv3_2Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv3_3Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv3_3Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv2_parentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the parent Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_parentBefore.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv1_grandparentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the grandparent Individual Score Detail should be 0 before updating! Actual: ' + isdlv1_grandparentBefore.reduivy__Weighted_Score__c);
        isdlv3_1Before.reduivy__Weighted_Score__c = 10;
        isdlv3_2Before.reduivy__Weighted_Score__c = 5;
        isdlv3_3Before.reduivy__Weighted_Score__c = 2;
        
		System.runAs(FACULTY_USER){
            update new List<reduivy__Individual_Score_Detail__c> {isdlv3_1Before, isdlv3_2Before, isdlv3_3Before};
		}

        
        reduivy__Individual_Score_Detail__c isdlv3_1After = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv3_2After = queryIsd(ISD_LV3_2_SRC);
        reduivy__Individual_Score_Detail__c isdlv3_3After = queryIsd(ISD_LV3_3_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentAfter = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentAfter = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdlv3_1After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(5, isdlv3_2After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 5!');
        System.Assert.areEqual(2, isdlv3_3After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 2!');
        System.Assert.areNotEqual(17, isdlv2_parentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should not be 17!');
        System.Assert.areEqual(15, isdlv2_parentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15 instead of 17!');
        System.Assert.areEqual(15, isdlv1_grandparentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15!');

        Test.stopTest();
		
    }

    /**
     * @description Test as faculty for updating parent score detail of score details
     */
    @IsTest
    static void testForUpdate_ChangeParentScoreDetail_AsFaculty() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        
        
        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        reduivy__Individual_Score_Detail__c isdlv3_1Before = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentBefore = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_1Before = queryIsd(ISD_LV2_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentBefore = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.isTrue(isNullor0(isdlv3_1Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv3_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv2_parentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the parent Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_parentBefore.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv2_1Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv1_grandparentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the grandparent Individual Score Detail should be 0 before updating! Actual: ' + isdlv1_grandparentBefore.reduivy__Weighted_Score__c);
        isdlv3_1Before.reduivy__Weighted_Score__c = 10;
        isdlv2_1Before.reduivy__Weighted_Score__c = 5;
        
        update new List<reduivy__Individual_Score_Detail__c> {isdlv3_1Before, isdlv2_1Before};
		
        reduivy__Individual_Score_Detail__c isdlv3_1After = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentAfter = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_1After = queryIsd(ISD_LV2_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentAfter = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdlv3_1After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(10, isdlv2_parentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(5, isdlv2_1After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 5!');
        System.Assert.areEqual(15, isdlv1_grandparentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15!');

        isdlv3_1After.reduivy__Parent_Score_Detail__c = isdlv1_grandparentAfter.Id;
        isdlv2_1After.reduivy__Parent_Score_Detail__c = isdlv2_parentAfter.Id;

		System.runAs(FACULTY_USER){
            update new List<reduivy__Individual_Score_Detail__c> {isdlv3_1After, isdlv2_1After};
		}

        reduivy__Individual_Score_Detail__c isdlv3_1AfterUpdate = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentAfterUpdate = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_1AfterUpdate = queryIsd(ISD_LV2_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentAfterUpdate = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdlv3_1AfterUpdate.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(5, isdlv2_parentAfterUpdate.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 5!');
        System.Assert.areEqual(5, isdlv2_1AfterUpdate.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 5!');
        System.Assert.areEqual(15, isdlv1_grandparentAfterUpdate.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15!');

        Test.stopTest();
    }
    
    /**
     * @description Test as faculty for deleting and undeleting weighted score of 1 lv2 children score details
     */
    @IsTest
    static void testForDeleteUndelete_1WeightedScoreLv2_AsFaculty() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();


        reduivy__Individual_Score_Detail__c isdlv2_1Before = queryIsd(ISD_LV2_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_parentBefore = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.isTrue(isNullor0(isdlv2_1Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv1_parentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the parent Individual Score Detail should be 0 before updating! Actual: ' + isdlv1_parentBefore.reduivy__Weighted_Score__c);
        isdlv2_1Before.reduivy__Weighted_Score__c = 10;
        
		System.runAs(FACULTY_USER){
            update isdlv2_1Before;
		}

        reduivy__Individual_Score_Detail__c isdlv2_1After = queryIsd(ISD_LV2_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_parentAfter = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdlv2_1After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(10, isdlv1_parentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 10!');

		System.runAs(FACULTY_USER){
            delete isdlv2_1After;
        }

        reduivy__Individual_Score_Detail__c isdlv1_parentAfterDelete = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(0, isdlv1_parentAfterDelete.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 0!');

		System.runAs(FACULTY_USER){
            undelete isdlv2_1After;
        }

        reduivy__Individual_Score_Detail__c isdlv1_parentAfterUndelete = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdlv1_parentAfterUndelete.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 10!');
        

        Test.stopTest();
		
    }

    /**
     * @description Test as faculty for deleting and undeleting weighted score of 2 lv2 children score details
     */
    @IsTest
    static void testForDeleteUndelete_2WeightedScoreLv2_AsFaculty() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        reduivy__Individual_Score_Detail__c isdlv2_1Before = queryIsd(ISD_LV2_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_2Before = queryIsd(ISD_LV2_2_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_parentBefore = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.isTrue(isNullor0(isdlv2_1Before.reduivy__Weighted_Score__c), 'Weighted Score of the first child Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv2_2Before.reduivy__Weighted_Score__c), 'Weighted Score of the second child Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv1_parentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the parent Individual Score Detail should be 0 before updating! Actual: ' + isdlv1_parentBefore.reduivy__Weighted_Score__c);
        isdlv2_1Before.reduivy__Weighted_Score__c = 10;
        isdlv2_2Before.reduivy__Weighted_Score__c = 5;
        
        update new List<reduivy__Individual_Score_Detail__c> {isdlv2_1Before, isdlv2_2Before};

        reduivy__Individual_Score_Detail__c isdlv2_1After = queryIsd(ISD_LV2_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_2After = queryIsd(ISD_LV2_2_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_parentAfter = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdlv2_1After.reduivy__Weighted_Score__c, 'The weighted score of the first child Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(5, isdlv2_2After.reduivy__Weighted_Score__c, 'The weighted score of the second child Individual Score Detail should be updated to 5!');
        System.Assert.areEqual(15, isdlv1_parentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15!');

		System.runAs(FACULTY_USER){
            delete isdlv2_1After;
        }
        
        reduivy__Individual_Score_Detail__c isdlv1_parentAfterDelete = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(5, isdlv1_parentAfterDelete.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 5!');

        System.runAs(FACULTY_USER) {
            undelete isdlv2_1After;
        }

        reduivy__Individual_Score_Detail__c isdlv1_parentAfterUndelete = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(15, isdlv1_parentAfterUndelete.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as faculty for deleting and undeleting weighted score of 1 lv3 children score details
     */
    @IsTest
    static void testForDeleteUndelete_1WeightedScoreLv3_AsFaculty() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        reduivy__Individual_Score_Detail__c isdlv3_1Before = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentBefore = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentBefore = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.isTrue(isNullor0(isdlv3_1Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv3_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv2_parentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the parent Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_parentBefore.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv1_grandparentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the grandparent Individual Score Detail should be 0 before updating! Actual: ' + isdlv1_grandparentBefore.reduivy__Weighted_Score__c);
        isdlv3_1Before.reduivy__Weighted_Score__c = 10;
        
		System.runAs(FACULTY_USER){
            update isdlv3_1Before;
		}
        
        reduivy__Individual_Score_Detail__c isdlv3_1After = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentAfter = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentAfter = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdlv3_1After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(10, isdlv2_parentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(10, isdlv1_grandparentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 10!');

        
		System.runAs(FACULTY_USER){
            delete isdlv3_1After;
        }

        reduivy__Individual_Score_Detail__c isdlv2_parentAfterDelete = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentAfterDelete = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(0, isdlv2_parentAfterDelete.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 0!');
        System.Assert.areEqual(0, isdlv1_grandparentAfterDelete.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 0!');

		System.runAs(FACULTY_USER){
            undelete isdlv3_1After;
        }

        reduivy__Individual_Score_Detail__c isdlv2_parentAfterUndelete = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentAfterUndelete = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdlv2_parentAfterUndelete.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(10, isdlv1_grandparentAfterUndelete.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 10!');

        Test.stopTest();
    }

    /**
     * @description Test as faculty for deleting and undeleting weighted score of 2 lv3 children score details
     */
    @IsTest
    static void testForDeleteUndelete_2WeightedScoreLv3_AsFaculty() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();


        reduivy__Individual_Score_Detail__c isdlv3_1Before = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv3_2Before = queryIsd(ISD_LV3_2_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentBefore = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentBefore = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.isTrue(isNullor0(isdlv3_1Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv3_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv3_2Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv3_2Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv2_parentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the parent Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_parentBefore.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv1_grandparentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the grandparent Individual Score Detail should be 0 before updating! Actual: ' + isdlv1_grandparentBefore.reduivy__Weighted_Score__c);
        isdlv3_1Before.reduivy__Weighted_Score__c = 10;
        isdlv3_2Before.reduivy__Weighted_Score__c = 5;
        
		System.runAs(FACULTY_USER){
            update new List<reduivy__Individual_Score_Detail__c> {isdlv3_1Before, isdlv3_2Before};
		}

        
        reduivy__Individual_Score_Detail__c isdlv3_1After = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv3_2After = queryIsd(ISD_LV3_2_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentAfter = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentAfter = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdlv3_1After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(5, isdlv3_2After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 5!');
        System.Assert.areEqual(15, isdlv2_parentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15!');
        System.Assert.areEqual(15, isdlv1_grandparentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15!');

        System.runAs(FACULTY_USER) {
            delete isdlv3_1After;
        }

        reduivy__Individual_Score_Detail__c isdlv2_parentAfterDelete = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentAfterDelete = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(5, isdlv2_parentAfterDelete.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 5!');
        System.Assert.areEqual(5, isdlv1_grandparentAfterDelete.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 5!');


        System.runAs(FACULTY_USER) {
            undelete isdlv3_1After;
        }

        reduivy__Individual_Score_Detail__c isdlv2_parentAfterUndelete = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentAfterUndelete = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(15, isdlv2_parentAfterUndelete.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15!');
        System.Assert.areEqual(15, isdlv1_grandparentAfterUndelete.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15!');



        Test.stopTest();
		
    }
    
    /**
     * @description Test as faculty for deleting and undeleting weighted score of 1 lv2 children score details and 1 lv3 children score details
     */
    @IsTest
    static void testForDeleteUndelete_1WeightedScoreLv3_1WeightedScoreLv2_AsFaculty() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        

        User FACULTY_USER = testFactory.getReduFacultyUser();

        Test.startTest();

        reduivy__Individual_Score_Detail__c isdlv3_1Before = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentBefore = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_1Before = queryIsd(ISD_LV2_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentBefore = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.isTrue(isNullor0(isdlv3_1Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv3_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv2_parentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the parent Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_parentBefore.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv2_1Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv1_grandparentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the grandparent Individual Score Detail should be 0 before updating! Actual: ' + isdlv1_grandparentBefore.reduivy__Weighted_Score__c);
        isdlv3_1Before.reduivy__Weighted_Score__c = 10;
        isdlv2_1Before.reduivy__Weighted_Score__c = 5;
        
		System.runAs(FACULTY_USER){
            update new List<reduivy__Individual_Score_Detail__c> {isdlv3_1Before, isdlv2_1Before};
		}

        reduivy__Individual_Score_Detail__c isdlv3_1After = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentAfter = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_1After = queryIsd(ISD_LV2_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentAfter = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdlv3_1After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(10, isdlv2_parentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(5, isdlv2_1After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 5!');
        System.Assert.areEqual(15, isdlv1_grandparentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15!');

		System.runAs(FACULTY_USER){
            delete isdlv3_1After;
		}
        
        reduivy__Individual_Score_Detail__c isdlv2_parentAfterDelete = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentAfterDelete = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(0, isdlv2_parentAfterDelete.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 0!');
        System.Assert.areEqual(5, isdlv1_grandparentAfterDelete.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 5!');

		System.runAs(FACULTY_USER){
            undelete isdlv3_1After;
		}
        
        reduivy__Individual_Score_Detail__c isdlv2_parentAfterUndelete = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentAfterUndelete = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdlv2_parentAfterUndelete.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(15, isdlv1_grandparentAfterUndelete.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15!');


        Test.stopTest();
		
    }
    
    /**
     * @description Test as student for inserting weighted score of 1 lv2 children score details
     */
	@IsTest
    static void testForInsert_1WeightedScoreLv2_AsStudent(){
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        
        User studentUser = testFactory.getStudentUser();
        Test.startTest();

        reduivy__Individual_Score__c parentIsc = queryIsc();
        reduivy__Individual_Score_Detail__c isd_lv1_parentBefore = queryIsd(ISD_LV1_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdToInsert = new reduivy__Individual_Score_Detail__c(
            reduivy__Individual_Score__c = parentIsc.Id,
            reduivy__Parent_Score_Detail__c = isd_lv1_parentBefore.Id,
            reduivy__Weighted_Score__c = 10,
            reduivy__Weight__c = 100,
            reduivy__Status__c = ISD_Helper.STATUS_ACTIVE
        );

        System.Assert.isTrue(isNullor0(isd_lv1_parentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the parent Individual Score Detail should be 0 before inserting! Actual: ' + isd_lv1_parentBefore.reduivy__Weighted_Score__c);

        System.runAs(studentUser) {
            insert isdToInsert;
        }

        reduivy__Individual_Score_Detail__c isd_lv1_parentAfter = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdToInsert.reduivy__Weighted_Score__c, 'Weighted Score of the child Individual Score Detail should be 10 after inserted!');
        System.Assert.areEqual(10, isd_lv1_parentAfter.reduivy__Weighted_Score__c, 'Weighted Score of the parent Individual Score Detail should be 10 after inserted!');

        Test.stopTest();
    }

    /**
     * @description Test as student for inserting weighted score of 2 lv2 children score details
     */
	@IsTest
    static void testForInsert_2WeightedScoreLv2_AsStudent(){
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        
        User studentUser = testFactory.getStudentUser();
        Test.startTest();

        reduivy__Individual_Score__c parentIsc = queryIsc();
        reduivy__Individual_Score_Detail__c isd_lv1_parentBefore = queryIsd(ISD_LV1_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdToInsert1 = new reduivy__Individual_Score_Detail__c(
            reduivy__Individual_Score__c = parentIsc.Id,
            reduivy__Parent_Score_Detail__c = isd_lv1_parentBefore.Id,
            reduivy__Weighted_Score__c = 10,
            reduivy__Weight__c = 100,
            reduivy__Status__c = ISD_Helper.STATUS_ACTIVE
        );
        reduivy__Individual_Score_Detail__c isdToInsert2 = new reduivy__Individual_Score_Detail__c(
            reduivy__Individual_Score__c = parentIsc.Id,
            reduivy__Parent_Score_Detail__c = isd_lv1_parentBefore.Id,
            reduivy__Weighted_Score__c = 5,
            reduivy__Weight__c = 100,
            reduivy__Status__c = ISD_Helper.STATUS_ACTIVE
        );

        System.Assert.isTrue(isNullor0(isd_lv1_parentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the parent Individual Score Detail should be 0 before inserting! Actual: ' + isd_lv1_parentBefore.reduivy__Weighted_Score__c);

        System.runAs(studentUser) {
            insert new List<reduivy__Individual_Score_Detail__c> {isdToInsert1, isdToInsert2};
        }

        reduivy__Individual_Score_Detail__c isd_lv1_parentAfter = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdToInsert1.reduivy__Weighted_Score__c, 'Weighted Score of the child Individual Score Detail should be 10 after inserted!');
        System.Assert.areEqual(5, isdToInsert2.reduivy__Weighted_Score__c, 'Weighted Score of the child Individual Score Detail should be 5 after inserted!');
        System.Assert.areEqual(15, isd_lv1_parentAfter.reduivy__Weighted_Score__c, 'Weighted Score of the parent Individual Score Detail should be 15 after inserted!');

        Test.stopTest();
    }

    /**
     * @description Test as student for inserting weighted score of 1 lv2 children score detail and 1 lv3 children score detail
     */
	@IsTest
    static void testForInsert_1WeightedScoreLv2_1WeightedScoreLv3_AsStudent(){
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        
        User studentUser = testFactory.getStudentUser();
        Test.startTest();

        reduivy__Individual_Score__c parentIsc = queryIsc();
        reduivy__Individual_Score_Detail__c isd_lv1_parentBefore = queryIsd(ISD_LV1_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isd_lv2_parentBefore = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdToInsert1 = new reduivy__Individual_Score_Detail__c(
            reduivy__Individual_Score__c = parentIsc.Id,
            reduivy__Parent_Score_Detail__c = isd_lv1_parentBefore.Id,
            reduivy__Weighted_Score__c = 10,
            reduivy__Weight__c = 100,
            reduivy__Status__c = ISD_Helper.STATUS_ACTIVE
        );
        reduivy__Individual_Score_Detail__c isdToInsert2 = new reduivy__Individual_Score_Detail__c(
            reduivy__Individual_Score__c = parentIsc.Id,
            reduivy__Parent_Score_Detail__c = isd_lv2_parentBefore.Id,
            reduivy__Weighted_Score__c = 5,
            reduivy__Weight__c = 100,
            reduivy__Status__c = ISD_Helper.STATUS_ACTIVE
        );

        System.Assert.isTrue(isNullor0(isd_lv1_parentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the parent Individual Score Detail should be 0 before inserting! Actual: ' + isd_lv1_parentBefore.reduivy__Weighted_Score__c);

        System.runAs(studentUser) {
            insert new List<reduivy__Individual_Score_Detail__c> {isdToInsert1, isdToInsert2};
        }

        reduivy__Individual_Score_Detail__c isd_lv1_parentAfter = queryIsd(ISD_LV1_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isd_lv2_parentAfter = queryIsd(ISD_LV2_PARENT_SRC);
        System.Assert.areEqual(10, isdToInsert1.reduivy__Weighted_Score__c, 'Weighted Score of the child Individual Score Detail should be 10 after inserted!');
        System.Assert.areEqual(5, isdToInsert2.reduivy__Weighted_Score__c, 'Weighted Score of the child Individual Score Detail should be 5 after inserted!');
        System.Assert.areEqual(15, isd_lv1_parentAfter.reduivy__Weighted_Score__c, 'Weighted Score of the parent Individual Score Detail should be 15 after inserted!');
        System.Assert.areEqual(5, isd_lv2_parentAfter.reduivy__Weighted_Score__c, 'Weighted Score of the parent Individual Score Detail should be 15 after inserted!');

        Test.stopTest();
    }

    /**
     * @description Test as student for updating weighted score of 1 lv2 children score details
     */
    @IsTest
    static void testForUpdate_1WeightedScoreLv2_AsStudent() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        

        User studentUser = testFactory.getStudentUser();

        Test.startTest();


        reduivy__Individual_Score_Detail__c isdlv2_1Before = queryIsd(ISD_LV2_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_parentBefore = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.isTrue(isNullor0(isdlv2_1Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv1_parentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the parent Individual Score Detail should be 0 before updating! Actual: ' + isdlv1_parentBefore.reduivy__Weighted_Score__c);
        isdlv2_1Before.reduivy__Weighted_Score__c = 10;
        
		System.runAs(studentUser){
            update isdlv2_1Before;
		}

        
        reduivy__Individual_Score_Detail__c isdlv2_1After = queryIsd(ISD_LV2_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_parentAfter = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdlv2_1After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(10, isdlv1_parentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 10!');

        Test.stopTest();
		
    }

    /**
     * @description Test as student for updating weighted score of 2 lv2 children score details
     */
    @IsTest
    static void testForUpdate_2WeightedScoreLv2_AsStudent() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        

        User studentUser = testFactory.getStudentUser();

        Test.startTest();

        reduivy__Individual_Score_Detail__c isdlv2_1Before = queryIsd(ISD_LV2_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_2Before = queryIsd(ISD_LV2_2_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_parentBefore = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.isTrue(isNullor0(isdlv2_1Before.reduivy__Weighted_Score__c), 'Weighted Score of the first child Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv2_2Before.reduivy__Weighted_Score__c), 'Weighted Score of the second child Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv1_parentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the parent Individual Score Detail should be 0 before updating! Actual: ' + isdlv1_parentBefore.reduivy__Weighted_Score__c);
        isdlv2_1Before.reduivy__Weighted_Score__c = 10;
        isdlv2_2Before.reduivy__Weighted_Score__c = 5;
        
		System.runAs(studentUser){
            update new List<reduivy__Individual_Score_Detail__c> {isdlv2_1Before, isdlv2_2Before};
		}

        
        reduivy__Individual_Score_Detail__c isdlv2_1After = queryIsd(ISD_LV2_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_2After = queryIsd(ISD_LV2_2_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_parentAfter = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdlv2_1After.reduivy__Weighted_Score__c, 'The weighted score of the first child Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(5, isdlv2_2After.reduivy__Weighted_Score__c, 'The weighted score of the second child Individual Score Detail should be updated to 5!');
        System.Assert.areEqual(15, isdlv1_parentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15!');

        Test.stopTest();
		
    }
    
	
    /**
     * @description Test as student for updating weighted score of 1 lv3 children score details
     */
    @IsTest
    static void testForUpdate_1WeightedScoreLv3_AsStudent() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        

        User studentUser = testFactory.getStudentUser();

        Test.startTest();


        reduivy__Individual_Score_Detail__c isdlv3_1Before = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentBefore = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentBefore = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.isTrue(isNullor0(isdlv3_1Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv3_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv2_parentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the parent Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_parentBefore.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv1_grandparentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the grandparent Individual Score Detail should be 0 before updating! Actual: ' + isdlv1_grandparentBefore.reduivy__Weighted_Score__c);
        isdlv3_1Before.reduivy__Weighted_Score__c = 10;
        
		System.runAs(studentUser){
            update isdlv3_1Before;
		}

        
        reduivy__Individual_Score_Detail__c isdlv3_1After = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentAfter = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentAfter = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdlv3_1After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(10, isdlv2_parentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(10, isdlv1_grandparentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 10!');

        Test.stopTest();
		
    }

	
    /**
     * @description Test as student for updating weighted score of 2 lv3 children score details
     */
    @IsTest
    static void testForUpdate_2WeightedScoreLv3_AsStudent() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        

        User studentUser = testFactory.getStudentUser();

        Test.startTest();


        reduivy__Individual_Score_Detail__c isdlv3_1Before = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv3_2Before = queryIsd(ISD_LV3_2_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentBefore = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentBefore = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.isTrue(isNullor0(isdlv3_1Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv3_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv3_2Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv3_2Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv2_parentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the parent Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_parentBefore.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv1_grandparentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the grandparent Individual Score Detail should be 0 before updating! Actual: ' + isdlv1_grandparentBefore.reduivy__Weighted_Score__c);
        isdlv3_1Before.reduivy__Weighted_Score__c = 10;
        isdlv3_2Before.reduivy__Weighted_Score__c = 5;
        
		System.runAs(studentUser){
            update new List<reduivy__Individual_Score_Detail__c> {isdlv3_1Before, isdlv3_2Before};
		}

        
        reduivy__Individual_Score_Detail__c isdlv3_1After = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv3_2After = queryIsd(ISD_LV3_2_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentAfter = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentAfter = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdlv3_1After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(5, isdlv3_2After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 5!');
        System.Assert.areEqual(15, isdlv2_parentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15!');
        System.Assert.areEqual(15, isdlv1_grandparentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15!');

        Test.stopTest();
		
    }
    
    /**
     * @description Test as student for updating weighted score of 1 lv3 children score details and 1 lv2 children score details
     */
    @IsTest
    static void testForUpdate_1WeightedScoreLv3_1WeightedScoreLv2_AsStudent() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        

        User studentUser = testFactory.getStudentUser();

        Test.startTest();

        reduivy__Individual_Score_Detail__c isdlv3_1Before = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentBefore = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_1Before = queryIsd(ISD_LV2_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentBefore = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.isTrue(isNullor0(isdlv3_1Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv3_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv2_parentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the parent Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_parentBefore.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv2_1Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv1_grandparentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the grandparent Individual Score Detail should be 0 before updating! Actual: ' + isdlv1_grandparentBefore.reduivy__Weighted_Score__c);
        isdlv3_1Before.reduivy__Weighted_Score__c = 10;
        isdlv2_1Before.reduivy__Weighted_Score__c = 5;
        
		System.runAs(studentUser){
            update new List<reduivy__Individual_Score_Detail__c> {isdlv3_1Before, isdlv2_1Before};
		}

        reduivy__Individual_Score_Detail__c isdlv3_1After = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentAfter = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_1After = queryIsd(ISD_LV2_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentAfter = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdlv3_1After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(10, isdlv2_parentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15!');
        System.Assert.areEqual(5, isdlv2_1After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 5!');
        System.Assert.areEqual(15, isdlv1_grandparentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as student for updating weighted score of 2 lv3 children score details, rollup parent exceeded max score
     */
    @IsTest
    static void testForUpdate_2WeightedScoreLv3_ParentMax_AsStudent() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        

        User studentUser = testFactory.getStudentUser();

        Test.startTest();

        reduivy__Individual_Score_Detail__c isdlv3_1Before = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv3_2Before = queryIsd(ISD_LV3_2_SRC);
        reduivy__Individual_Score_Detail__c isdlv3_3Before = queryIsd(ISD_LV3_3_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentBefore = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentBefore = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.isTrue(isNullor0(isdlv3_1Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv3_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv3_2Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv3_2Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv3_3Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv3_3Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv2_parentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the parent Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_parentBefore.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv1_grandparentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the grandparent Individual Score Detail should be 0 before updating! Actual: ' + isdlv1_grandparentBefore.reduivy__Weighted_Score__c);
        isdlv3_1Before.reduivy__Weighted_Score__c = 10;
        isdlv3_2Before.reduivy__Weighted_Score__c = 5;
        isdlv3_3Before.reduivy__Weighted_Score__c = 2;
        
		System.runAs(studentUser){
            update new List<reduivy__Individual_Score_Detail__c> {isdlv3_1Before, isdlv3_2Before, isdlv3_3Before};
		}

        
        reduivy__Individual_Score_Detail__c isdlv3_1After = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv3_2After = queryIsd(ISD_LV3_2_SRC);
        reduivy__Individual_Score_Detail__c isdlv3_3After = queryIsd(ISD_LV3_3_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentAfter = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentAfter = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdlv3_1After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(5, isdlv3_2After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 5!');
        System.Assert.areEqual(2, isdlv3_3After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 2!');
        System.Assert.areNotEqual(17, isdlv2_parentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should not be 17!');
        System.Assert.areEqual(15, isdlv2_parentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15 instead of 17!');
        System.Assert.areEqual(15, isdlv1_grandparentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15!');

        Test.stopTest();
		
    }

    /**
     * @description Test as student for updating parent score detail of score details
     */
    @IsTest
    static void testForUpdate_ChangeParentScoreDetail_AsStudent() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        
        
        User studentUser = testFactory.getStudentUser();

        Test.startTest();

        reduivy__Individual_Score_Detail__c isdlv3_1Before = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentBefore = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_1Before = queryIsd(ISD_LV2_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentBefore = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.isTrue(isNullor0(isdlv3_1Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv3_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv2_parentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the parent Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_parentBefore.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv2_1Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv1_grandparentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the grandparent Individual Score Detail should be 0 before updating! Actual: ' + isdlv1_grandparentBefore.reduivy__Weighted_Score__c);
        isdlv3_1Before.reduivy__Weighted_Score__c = 10;
        isdlv2_1Before.reduivy__Weighted_Score__c = 5;
        
        update new List<reduivy__Individual_Score_Detail__c> {isdlv3_1Before, isdlv2_1Before};
		
        reduivy__Individual_Score_Detail__c isdlv3_1After = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentAfter = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_1After = queryIsd(ISD_LV2_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentAfter = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdlv3_1After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(10, isdlv2_parentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(5, isdlv2_1After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 5!');
        System.Assert.areEqual(15, isdlv1_grandparentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15!');

        isdlv3_1After.reduivy__Parent_Score_Detail__c = isdlv1_grandparentAfter.Id;
        isdlv2_1After.reduivy__Parent_Score_Detail__c = isdlv2_parentAfter.Id;

		System.runAs(studentUser){
            update new List<reduivy__Individual_Score_Detail__c> {isdlv3_1After, isdlv2_1After};
		}

        reduivy__Individual_Score_Detail__c isdlv3_1AfterUpdate = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentAfterUpdate = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_1AfterUpdate = queryIsd(ISD_LV2_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentAfterUpdate = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdlv3_1AfterUpdate.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(5, isdlv2_parentAfterUpdate.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 5!');
        System.Assert.areEqual(5, isdlv2_1AfterUpdate.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 5!');
        System.Assert.areEqual(15, isdlv1_grandparentAfterUpdate.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15!');

        Test.stopTest();
    }
    
    /**
     * @description Test as student for deleting and undeleting weighted score of 1 lv2 children score details
     */
    @IsTest
    static void testForDeleteUndelete_1WeightedScoreLv2_AsStudent() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        

        User studentUser = testFactory.getStudentUser();

        Test.startTest();


        reduivy__Individual_Score_Detail__c isdlv2_1Before = queryIsd(ISD_LV2_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_parentBefore = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.isTrue(isNullor0(isdlv2_1Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv1_parentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the parent Individual Score Detail should be 0 before updating! Actual: ' + isdlv1_parentBefore.reduivy__Weighted_Score__c);
        isdlv2_1Before.reduivy__Weighted_Score__c = 10;
        
		System.runAs(studentUser){
            update isdlv2_1Before;
		}

        reduivy__Individual_Score_Detail__c isdlv2_1After = queryIsd(ISD_LV2_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_parentAfter = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdlv2_1After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(10, isdlv1_parentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 10!');

		System.runAs(studentUser){
            delete isdlv2_1After;
        }

        reduivy__Individual_Score_Detail__c isdlv1_parentAfterDelete = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(0, isdlv1_parentAfterDelete.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 0!');

		System.runAs(studentUser){
            undelete isdlv2_1After;
        }

        reduivy__Individual_Score_Detail__c isdlv1_parentAfterUndelete = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdlv1_parentAfterUndelete.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 10!');
        

        Test.stopTest();
		
    }

    /**
     * @description Test as student for deleting and undeleting weighted score of 2 lv2 children score details
     */
    @IsTest
    static void testForDeleteUndelete_2WeightedScoreLv2_AsStudent() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        

        User studentUser = testFactory.getStudentUser();

        Test.startTest();

        reduivy__Individual_Score_Detail__c isdlv2_1Before = queryIsd(ISD_LV2_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_2Before = queryIsd(ISD_LV2_2_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_parentBefore = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.isTrue(isNullor0(isdlv2_1Before.reduivy__Weighted_Score__c), 'Weighted Score of the first child Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv2_2Before.reduivy__Weighted_Score__c), 'Weighted Score of the second child Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv1_parentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the parent Individual Score Detail should be 0 before updating! Actual: ' + isdlv1_parentBefore.reduivy__Weighted_Score__c);
        isdlv2_1Before.reduivy__Weighted_Score__c = 10;
        isdlv2_2Before.reduivy__Weighted_Score__c = 5;
        
        update new List<reduivy__Individual_Score_Detail__c> {isdlv2_1Before, isdlv2_2Before};

        reduivy__Individual_Score_Detail__c isdlv2_1After = queryIsd(ISD_LV2_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_2After = queryIsd(ISD_LV2_2_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_parentAfter = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdlv2_1After.reduivy__Weighted_Score__c, 'The weighted score of the first child Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(5, isdlv2_2After.reduivy__Weighted_Score__c, 'The weighted score of the second child Individual Score Detail should be updated to 5!');
        System.Assert.areEqual(15, isdlv1_parentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15!');

		System.runAs(studentUser){
            delete isdlv2_1After;
        }
        
        reduivy__Individual_Score_Detail__c isdlv1_parentAfterDelete = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(5, isdlv1_parentAfterDelete.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 5!');

        System.runAs(studentUser) {
            undelete isdlv2_1After;
        }

        reduivy__Individual_Score_Detail__c isdlv1_parentAfterUndelete = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(15, isdlv1_parentAfterUndelete.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15!');

        Test.stopTest();
		
    }
	
    /**
     * @description Test as student for deleting and undeleting weighted score of 1 lv3 children score details
     */
    @IsTest
    static void testForDeleteUndelete_1WeightedScoreLv3_AsStudent() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        

        User studentUser = testFactory.getStudentUser();

        Test.startTest();

        reduivy__Individual_Score_Detail__c isdlv3_1Before = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentBefore = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentBefore = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.isTrue(isNullor0(isdlv3_1Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv3_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv2_parentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the parent Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_parentBefore.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv1_grandparentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the grandparent Individual Score Detail should be 0 before updating! Actual: ' + isdlv1_grandparentBefore.reduivy__Weighted_Score__c);
        isdlv3_1Before.reduivy__Weighted_Score__c = 10;
        
		System.runAs(studentUser){
            update isdlv3_1Before;
		}
        
        reduivy__Individual_Score_Detail__c isdlv3_1After = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentAfter = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentAfter = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdlv3_1After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(10, isdlv2_parentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(10, isdlv1_grandparentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 10!');

        
		System.runAs(studentUser){
            delete isdlv3_1After;
        }

        reduivy__Individual_Score_Detail__c isdlv2_parentAfterDelete = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentAfterDelete = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(0, isdlv2_parentAfterDelete.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 0!');
        System.Assert.areEqual(0, isdlv1_grandparentAfterDelete.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 0!');

		System.runAs(studentUser){
            undelete isdlv3_1After;
        }

        reduivy__Individual_Score_Detail__c isdlv2_parentAfterUndelete = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentAfterUndelete = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdlv2_parentAfterUndelete.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(10, isdlv1_grandparentAfterUndelete.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 10!');

        Test.stopTest();
    }

    /**
     * @description Test as student for deleting and undeleting weighted score of 2 lv3 children score details
     */
    @IsTest
    static void testForDeleteUndelete_2WeightedScoreLv3_AsStudent() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        

        User studentUser = testFactory.getStudentUser();

        Test.startTest();


        reduivy__Individual_Score_Detail__c isdlv3_1Before = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv3_2Before = queryIsd(ISD_LV3_2_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentBefore = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentBefore = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.isTrue(isNullor0(isdlv3_1Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv3_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv3_2Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv3_2Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv2_parentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the parent Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_parentBefore.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv1_grandparentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the grandparent Individual Score Detail should be 0 before updating! Actual: ' + isdlv1_grandparentBefore.reduivy__Weighted_Score__c);
        isdlv3_1Before.reduivy__Weighted_Score__c = 10;
        isdlv3_2Before.reduivy__Weighted_Score__c = 5;
        
		System.runAs(studentUser){
            update new List<reduivy__Individual_Score_Detail__c> {isdlv3_1Before, isdlv3_2Before};
		}

        
        reduivy__Individual_Score_Detail__c isdlv3_1After = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv3_2After = queryIsd(ISD_LV3_2_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentAfter = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentAfter = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdlv3_1After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(5, isdlv3_2After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 5!');
        System.Assert.areEqual(15, isdlv2_parentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15!');
        System.Assert.areEqual(15, isdlv1_grandparentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15!');

        System.runAs(studentUser) {
            delete isdlv3_1After;
        }

        reduivy__Individual_Score_Detail__c isdlv2_parentAfterDelete = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentAfterDelete = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(5, isdlv2_parentAfterDelete.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 5!');
        System.Assert.areEqual(5, isdlv1_grandparentAfterDelete.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 5!');


        System.runAs(studentUser) {
            undelete isdlv3_1After;
        }

        reduivy__Individual_Score_Detail__c isdlv2_parentAfterUndelete = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentAfterUndelete = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(15, isdlv2_parentAfterUndelete.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15!');
        System.Assert.areEqual(15, isdlv1_grandparentAfterUndelete.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15!');



        Test.stopTest();
		
    }
    
    /**
     * @description Test as student for deleting and undeleting weighted score of 1 lv2 children score details and 1 lv3 children score details
     */
    @IsTest
    static void testForDeleteUndelete_1WeightedScoreLv3_1WeightedScoreLv2_AsStudent() {
        
        if(!IPA_Helper.canRunEvaluationTest()){
            return;
        }
        

        User studentUser = testFactory.getStudentUser();

        Test.startTest();

        reduivy__Individual_Score_Detail__c isdlv3_1Before = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentBefore = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_1Before = queryIsd(ISD_LV2_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentBefore = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.isTrue(isNullor0(isdlv3_1Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv3_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv2_parentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the parent Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_parentBefore.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv2_1Before.reduivy__Weighted_Score__c), 'Weighted Score of the child Individual Score Detail should be 0 before updating! Actual: ' + isdlv2_1Before.reduivy__Weighted_Score__c);
        System.Assert.isTrue(isNullor0(isdlv1_grandparentBefore.reduivy__Weighted_Score__c), 'Weighted Score of the grandparent Individual Score Detail should be 0 before updating! Actual: ' + isdlv1_grandparentBefore.reduivy__Weighted_Score__c);
        isdlv3_1Before.reduivy__Weighted_Score__c = 10;
        isdlv2_1Before.reduivy__Weighted_Score__c = 5;
        
		System.runAs(studentUser){
            update new List<reduivy__Individual_Score_Detail__c> {isdlv3_1Before, isdlv2_1Before};
		}

        reduivy__Individual_Score_Detail__c isdlv3_1After = queryIsd(ISD_LV3_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_parentAfter = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv2_1After = queryIsd(ISD_LV2_1_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentAfter = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdlv3_1After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(10, isdlv2_parentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(5, isdlv2_1After.reduivy__Weighted_Score__c, 'The weighted score of the child Individual Score Detail should be updated to 5!');
        System.Assert.areEqual(15, isdlv1_grandparentAfter.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15!');

		System.runAs(studentUser){
            delete isdlv3_1After;
		}
        
        reduivy__Individual_Score_Detail__c isdlv2_parentAfterDelete = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentAfterDelete = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(0, isdlv2_parentAfterDelete.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 0!');
        System.Assert.areEqual(5, isdlv1_grandparentAfterDelete.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 5!');

		System.runAs(studentUser){
            undelete isdlv3_1After;
		}
        
        reduivy__Individual_Score_Detail__c isdlv2_parentAfterUndelete = queryIsd(ISD_LV2_PARENT_SRC);
        reduivy__Individual_Score_Detail__c isdlv1_grandparentAfterUndelete = queryIsd(ISD_LV1_PARENT_SRC);
        System.Assert.areEqual(10, isdlv2_parentAfterUndelete.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 10!');
        System.Assert.areEqual(15, isdlv1_grandparentAfterUndelete.reduivy__Weighted_Score__c, 'The weighted score of the parent Individual Score Detail should be updated to 15!');


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
            SELECT Id, Name, reduivy__Total_Score__c
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