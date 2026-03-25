/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Test
 * @description Test class for REDU_License_SCHED
 * @changehistory
 */
@isTest
public inherited sharing class REDU_License_SCHED_TEST {

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
            testFactory.initSampleData();
        }
    }
	
    @IsTest
    static void testScheduler(){
        
        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        
        System.runAs(ADMIN_USER){
            String jobId = System.schedule('REDU_License_SCHED', REDU_AppSetting_UTIL.getLicenseScheduleJobFrequency(), new REDU_License_SCHED());
            
            System.Assert.isNotNull(jobId, 'Failed to schedule the license count job.');
        }

        Test.stopTest();
        
    }
	
}