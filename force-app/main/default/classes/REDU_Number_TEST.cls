/**
 * @author      WDCi (Lean)
 * @date        Mar 2025
 * @group       Test
 * @description Test class for REDU_Number_UTIL
 * @changehistory
 * ISS-002323 03-05-2025 Lean - new class
 */
@IsTest
public inherited sharing class REDU_Number_TEST {

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

    }
	
    /**
     * @description Test as admin
     */
    @IsTest
    static void testNumberMethods() {

        Test.startTest();
        
        System.Assert.areEqual(0.001, REDU_Number_UTIL.setScale(0.0010, 3));
        System.Assert.areEqual(0.002, REDU_Number_UTIL.setScale(0.0015, 3));
        System.Assert.areEqual(80.15, REDU_Number_UTIL.setScale(80.153, 2));
        System.Assert.areEqual(80.16, REDU_Number_UTIL.setScale(80.155, 2));

        Test.stopTest();
		
    }
	
}