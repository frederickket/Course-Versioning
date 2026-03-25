/**
 * @author      WDCi (Lean)
 * @date        Mar 2025
 * @group       Test
 * @description Test class for REDU_Toaster_LCTRL
 * @changehistory
 * ISS-002284 03-05-2025 Lean - new class
 */

@isTest
private class REDU_Toaster_TEST {

    /**
     * @description Initialise test environment
    */
    static REDU_TestData_FACTORY testFactory = new REDU_TestData_FACTORY();

    /**
     * @description Initialise test data for each test
    */
    @TestSetup
    static void makeData(){
        
        testFactory.setupDefaultSettings();

    }

    /**
     * @description Test get config by for type
     */
    @IsTest
    static void testGetToastConfigsByForType() {

        REDU_LightningResponse response = REDU_Toaster_LCTRL.getToasterConfigs();

        Map<String, Object> configMap = (Map<String, Object>) JSON.deserializeUntyped(response.responseData);

        System.Assert.areEqual(true, !configMap.isEmpty());
        System.Assert.areEqual(true, configMap.containsKey('info'));

        System.Assert.areEqual(true, configMap.containsKey('warning'));

        System.Assert.areEqual(true, configMap.containsKey('success'));

        System.Assert.areEqual(true, configMap.containsKey('error'));
    }

}