/**
 * @author      WDCi (XW)
 * @date        Nov 2025
 * @group       Wizard Form
 * @description Handle Wizard Form custom Metadata
 * @changehistory
 * ISS-002633 18-11-2025 XW - new class
 */

public inherited sharing class REDU_WizardConfigManager {

    static List<reduivy__Wizard_Config__mdt> wizardConfigs;

    /**
     * @description get all the wizard configs
     * @return List<reduivy__Wizard_Config__mdt>
     */
    public static List<reduivy__Wizard_Config__mdt> getWizardConfigs(){

        if (wizardConfigs == null) {

            wizardConfigs = new List<reduivy__Wizard_Config__mdt>();
            List<reduivy__Wizard_Config__mdt> configs = reduivy__Wizard_Config__mdt.getAll().values();

            for (reduivy__Wizard_Config__mdt config : configs) {
                if (config.reduivy__Active__c) {
                    wizardConfigs.add(config);
                }
            }
        }

        return wizardConfigs;
    }


	static Map<Id, reduivy__Wizard_Config__mdt> wizardConfigsMap;

    /**
     * @description get all the wizard configs with its id as key
     * @return MAP<Id,reduivy__Wizard_Config__mdt>
     */
    public static Map<Id, reduivy__Wizard_Config__mdt> getWizardConfigsMap(){

        if (wizardConfigsMap == null) {
            wizardConfigsMap = new Map<Id, reduivy__Wizard_Config__mdt>(getWizardConfigs());
        }

        return wizardConfigsMap;
    }
    
}