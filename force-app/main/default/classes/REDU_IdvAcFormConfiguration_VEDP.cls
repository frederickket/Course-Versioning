/**
 * @author      WDCi (XW)
 * @date        Nov 2025
 * @group       Student Achievement
 * @description 
 * @changehistory
 * ISS-002633 17-11-2025 XW - new class
 */

public with sharing class REDU_IdvAcFormConfiguration_VEDP extends VisualEditor.DynamicPickList {

    public override VisualEditor.DataRow getDefaultValue() {
        List<IAC_Helper.IdvAcWizardFormWrapper> wrapperList = IAC_Helper.getIdvAchievementWizardFormList();
        Map<Id, reduivy__Wizard_Config__mdt> wizardConfigsMap = REDU_WizardConfigManager.getWizardConfigsMap();

        VisualEditor.DataRow resultDataRow;
        if(wrapperList != null && !wrapperList.isEmpty() && wizardConfigsMap != null && !wizardConfigsMap.isEmpty()) {

            for (IAC_Helper.IdvAcWizardFormWrapper wrapper : wrapperList) {

                reduivy__Wizard_Config__mdt wizardConfig = wizardConfigsMap.get(wrapper.wizardConfig);
                if(String.isNotBlank(wrapper.wizardConfig) && wizardConfig != null) {
                    resultDataRow = new VisualEditor.DataRow(
                        wizardConfig.MasterLabel, 
                        wizardConfig.DeveloperName
                    );
                    break;
                }
            }
        }
        return resultDataRow ?? new VisualEditor.DataRow('', '');
    }

    /**
     * @description Get all the selectable values, which is all the Wizard configs that are looked up by the idvac form config
     * @return   return description
     */
    public override VisualEditor.DynamicPickListRows getValues() {
        
        VisualEditor.DynamicPickListRows resultRows = new VisualEditor.DynamicPickListRows();
        Map<Id, VisualEditor.DataRow> dataRowMap = new Map<Id, VisualEditor.DataRow>();
        List<IAC_Helper.IdvAcWizardFormWrapper> wrapperList = IAC_Helper.getIdvAchievementWizardFormList();
        Map<Id, reduivy__Wizard_Config__mdt> wizardConfigsMap = REDU_WizardConfigManager.getWizardConfigsMap();

        if(wrapperList != null && !wrapperList.isEmpty() && wizardConfigsMap != null && !wizardConfigsMap.isEmpty()) {
            for (IAC_Helper.IdvAcWizardFormWrapper wrapper : wrapperList) {

                reduivy__Wizard_Config__mdt wizardConfig = wizardConfigsMap.get(wrapper.wizardConfig);

                if(
                    String.isNotBlank(wrapper.wizardConfig) && 
                    wizardConfig != null && 
                    !dataRowMap.containsKey(wrapper.wizardConfig)
                ) {
                    VisualEditor.DataRow newRow = new VisualEditor.DataRow(
                        wizardConfig.MasterLabel, 
                        wizardConfig.DeveloperName
                    );
                    dataRowMap.put(wrapper.wizardConfig, newRow);
                }
            }
            resultRows.addAllRows(dataRowMap.values());
        }
        return resultRows;
    }
}
