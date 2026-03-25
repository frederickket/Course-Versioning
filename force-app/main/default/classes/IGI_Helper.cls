/**
 * @author      WDCi (Lean)
 * @date        Dec 2023
 * @group       Object Helper
 * @description Individual Grade Item object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * ISS-001918 08-08-2024 CM - Added getStatuses()
 */
global inherited sharing class IGI_Helper implements SObject_Helper {
    
    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Individual_Grade_Item__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Individual_Grade_Item__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Individual_Grade_Item__c.getName();
    }

    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Individual_Grade_Item__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }

    /**
     * @description Return active Status picklist options
     * @return List<Schema.PicklistEntry>
     */
    global static List<Schema.PicklistEntry> getStatuses() {
        Schema.DescribeFieldResult dfr = Schema.SObjectType.reduivy__Individual_Grade_Item__c.fields.reduivy__Status__c;
        List<Schema.PicklistEntry> pleList = dfr.getPicklistValues();
        List<Schema.PicklistEntry> activeStatusList = new List<Schema.PicklistEntry>();

        for (Schema.PicklistEntry ple : pleList) {
            if(ple.isActive()) {
                activeStatusList.add(ple);
            }
        }

        return activeStatusList;    
    }
	
}