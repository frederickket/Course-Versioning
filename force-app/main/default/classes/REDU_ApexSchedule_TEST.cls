/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Test
 * @description Test class for REDU_ApexSchedule_UTIL
 * @changehistory
 */
@IsTest
public inherited sharing class REDU_ApexSchedule_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();
    
	@TestSetup
    static void makeData(){
        
    }

    /**
     * @description Test scheduling a schedulable job
     */
    @IsTest
    static void testScheduleJob(){
        
        Test.startTest();
        String result = REDU_ApexSchedule_UTIL.scheduleJob('Test License Job', '0 0 0 ? * * *', 'REDU_License_SCHED', false, false);

        System.Assert.areEqual(true, String.isNotBlank(result));

        Test.stopTest();
        
    }

    /**
     * @description Test scheduling a schedulable job
     */
    @IsTest
    static void testInvalidScheduleJob(){
        
        Test.startTest();
        String result = REDU_ApexSchedule_UTIL.scheduleJob('Test License Job', '0 0 0 ? * * *', 'REDU_Invalid_Sched', false, true);

        System.Assert.areEqual(false, String.isNotBlank(result));

        Test.stopTest();
        
    }
	
}