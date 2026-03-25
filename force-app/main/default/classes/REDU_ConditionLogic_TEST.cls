/**
 * @author      WDCi (Jordan)
 * @date        Nov 2023
 * @group       Test
 * @description Test class for REDU_ConditionLogic_OBJ
 * @changehistory
 * 
 */
@isTest
public inherited sharing class REDU_ConditionLogic_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    /**
     * @description Default method to setup required data for automated test
     */
	@TestSetup
    static void makeData(){

    }

    /**
     * @description Test condition logic
     */
    @IsTest
    static void testConditionLogic(){

        //Set up requirements
        List<REDU_ConditionLogic_OBJ.Requirement> reqList = new List<REDU_ConditionLogic_OBJ.Requirement>();
        REDU_ConditionLogic_OBJ.Requirement req1 = new REDU_ConditionLogic_OBJ.Requirement('1', true);
        reqList.add(req1);
        REDU_ConditionLogic_OBJ.Requirement req2 = new REDU_ConditionLogic_OBJ.Requirement('2', false);
        reqList.add(req2);
        REDU_ConditionLogic_OBJ.Requirement req3 = new REDU_ConditionLogic_OBJ.Requirement('3', true);
        reqList.add(req3);
        REDU_ConditionLogic_OBJ.Requirement req4 = new REDU_ConditionLogic_OBJ.Requirement('4', false);
        reqList.add(req4);

        test.startTest();

        //Condition logic
        REDU_ConditionLogic_OBJ cl1 = new REDU_ConditionLogic_OBJ('1 OR 2 AND (3 AND 4)');
        REDU_ConditionLogic_OBJ cl2 = new REDU_ConditionLogic_OBJ('NOT(1 OR 2 AND (3 AND 4))');
        System.Assert.areEqual(false, cl1.valueOf(reqList));
        System.Assert.areEqual(true, cl2.valueOf(reqList));

        //Condition logic (lower case)
        REDU_ConditionLogic_OBJ cllc1 = new REDU_ConditionLogic_OBJ('1 or 2 and (3 and 4)');
        REDU_ConditionLogic_OBJ cllc2 = new REDU_ConditionLogic_OBJ('not(1 or 2 and (3 and 4))');
        System.Assert.areEqual(false, cllc1.valueOf(reqList));
        System.Assert.areEqual(true, cllc2.valueOf(reqList));

        //Condition logic (symbols)
        REDU_ConditionLogic_OBJ cls1 = new REDU_ConditionLogic_OBJ('1 | 2 & (3 & 4)');
        REDU_ConditionLogic_OBJ cls2 = new REDU_ConditionLogic_OBJ('!(1 | 2 & (3 & 4))');
        System.Assert.areEqual(false, cls1.valueOf(reqList));
        System.Assert.areEqual(true, cls2.valueOf(reqList));
        test.stopTest();

    }

}