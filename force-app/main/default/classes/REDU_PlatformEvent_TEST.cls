/**
 * @author      WDCi (Jordan)
 * @date        Nov 2024
 * @group       Test
 * @description Test class for REDU_PlatformEvent_UTIL
 * @changehistory
 * ISS-002153 20-11-2024 Jordan - new class
 */
@IsTest
public inherited sharing class REDU_PlatformEvent_TEST {

    /**
     * @description Initialise test environment
     */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    /**
     * @description Test platform event as admin
     */
    @IsTest
    static void testPlatformEventAsAdmin(){

        User ADMIN_USER = testFactory.getReduAdminUser();
        
        Test.startTest();
        System.runAs(ADMIN_USER) {
            SObject pfEvt = REDU_PlatformEvent_UTIL.initPlatformEvent('Test', 'Test', 'Test', 'Test');
            Database.SaveResult sr = REDU_PlatformEvent_UTIL.publishEvent(pfEvt);

            System.assert(sr.isSuccess(), 'Message failed to be published.');
        }

        Test.stopTest();
        
    }

}