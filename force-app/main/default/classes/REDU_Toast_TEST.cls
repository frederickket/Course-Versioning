/**
 * @author      WDCi (Lean)
 * @date        Mar 2025
 * @group       Test
 * @description Test class for REDU_Toast_UTIL
 * @changehistory
 * ISS-002284 03-05-2025 Lean - new class
 */

@isTest
private class REDU_Toast_TEST {

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
     * @description Test get config list
     */
    @IsTest
    static void testGetToastConfigs() {

        List<reduivy__LWC_Toast_Config__mdt> toastConfigs = REDU_Toast_UTIL.getToastConfigs();

        System.Assert.areEqual(true, !toastConfigs.isEmpty());
    }

    /**
     * @description Test get config by for type
     */
    @IsTest
    static void testGetToastConfigsByForType() {

        Map<String, reduivy__LWC_Toast_Config__mdt> configMap = REDU_Toast_UTIL.getToastConfigsByForType();

        System.Assert.areEqual(true, !configMap.isEmpty());
        System.Assert.areEqual(true, configMap.containsKey('info'));
        System.Assert.areEqual('info', configMap.get('info').reduivy__For_Type__c);

        System.Assert.areEqual(true, configMap.containsKey('warning'));
        System.Assert.areEqual('warning', configMap.get('warning').reduivy__For_Type__c);

        System.Assert.areEqual(true, configMap.containsKey('success'));
        System.Assert.areEqual('success', configMap.get('success').reduivy__For_Type__c);

        System.Assert.areEqual(true, configMap.containsKey('error'));
        System.Assert.areEqual('error', configMap.get('error').reduivy__For_Type__c);
    }

}