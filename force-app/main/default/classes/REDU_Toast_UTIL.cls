/**
 * @author      WDCi (Lean)
 * @date        Mar 2025
 * @group       Utility
 * @description Toast utility
 * @changehistory
 * ISS-002284 03-05-2025 Lean - new class
 */
public inherited sharing class REDU_Toast_UTIL {
    
    /**
     * @description List of reduivy__LWC_Toast_Config__mdt 
     */
    private static List<reduivy__LWC_Toast_Config__mdt> toastConfigs;

    /**
     * @description Return the list of reduivy__LWC_Toast_Config__mdt
     * @return List<reduivy__LWC_Toast_Config__mdt>
     */
    public static List<reduivy__LWC_Toast_Config__mdt> getToastConfigs() {

        if (toastConfigs == null) {
            
            toastConfigs = new List<reduivy__LWC_Toast_Config__mdt>();

            List<reduivy__LWC_Toast_Config__mdt> configs = reduivy__LWC_Toast_Config__mdt.getAll().values();
            for (reduivy__LWC_Toast_Config__mdt config : configs){
                if (config.reduivy__Active__c){
                    toastConfigs.add(config);
                }
            }
        }

        return toastConfigs;
    }

    /**
     * @description Return toast config by for type
     * @return Map<String, reduivy__LWC_Toast_Config__mdt>
     */
    public static Map<String, reduivy__LWC_Toast_Config__mdt> getToastConfigsByForType() {

        Map<String, reduivy__LWC_Toast_Config__mdt> configMap = new Map<String, reduivy__LWC_Toast_Config__mdt>();

        for (reduivy__LWC_Toast_Config__mdt config : getToastConfigs()){
            configMap.put(config.reduivy__For_Type__c, config);
        }

        return configMap;
    }
}