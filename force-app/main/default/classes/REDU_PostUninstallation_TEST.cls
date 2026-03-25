/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Test
 * @description Test class for REDU_PostUninstallation
 * @changehistory
 * 
 */
@isTest
public inherited sharing class REDU_PostUninstallation_TEST {
	
	@IsTest
    static void testUninstallScript(){
        
        Test.startTest();
    
        try {
            Test.testUninstall(new REDU_PostUninstallation());
        } catch (Exception exp) {
            System.Assert.fail(exp.getMessage());
        }

        Test.stopTest();
        
    }
}