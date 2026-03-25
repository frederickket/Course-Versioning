/**
 * @author      WDCi (Lean)
 * @date        Feb 2024
 * @group       Object Helper
 * @description Transaction Line Item object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * ISS-001986 22-07-2024 Sueanne - added option "Discount Entry"
 * ISS-002047 07-08-2024 XiRouh - added option "Tuition" for item type picklist
 */
global inherited sharing class TRL_Helper implements SObject_Helper {
    
    /**
     * @description Transaction Line Item Transaction Type picklist constants
     */
    global static final String TRANSACTION_TYPE_ORDERLINE = 'Order Line';

    /**
     * @description Transaction Line Item Transaction Type picklist constants
     */
    global static final String TRANSACTION_TYPE_MONETARYENTRY = 'Monetary Entry';

    /**
     * @description Transaction Line Item Transaction Type picklist constants
     */
    global static final String TRANSACTION_TYPE_DISCOUNTENTRY = 'Discount Entry';

    /**
     * @description Transaction Line Item Transaction Type picklist constants
     */
    global static final String TRANSACTION_TYPE_NONTRANSACTIONALENTRY = 'Non Transactional Entry';

    /**
     * @description Transaction Line Item Entry Type picklist constants
     */
    global static final String ENTRY_TYPE_CREDIT = 'Credit';

    /**
     * @description Transaction Line Item Entry Type picklist constants
     */
    global static final String ENTRY_TYPE_DEBIT = 'Debit';

    /**
     * @description Transaction Line Item Item Type picklist constants
     */
    global static final String ITEM_TYPE_TUITION = 'Tuition';

    /**
     * @description Transaction Line Item Item Type picklist constants
     */
    global static final String ITEM_TYPE_MISCELLANEOUS = 'Miscellaneous';

    /**
     * @description Return object type
     * @return String
     */
    public static Schema.SObjectType getObjectType() {
        return SObjectType.reduivy__Transaction_Line_Item__c.getSObjectType();
    }

    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Transaction_Line_Item__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Transaction_Line_Item__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Transaction_Line_Item__c.getName();
    }

    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Transaction_Line_Item__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }

    /**
     * @description List of reduivy__Transaction_Item_Type_Config__mdt
     */
    private static List<reduivy__Transaction_Item_Type_Config__mdt> prepaymentItemTypeConfigs;

    /**
     * @description Transaction Type configs metadata sorted according to sequence
     * @return List<reduivy__Transaction_Item_Type_Config__mdt>
     */
    public static Map<String, reduivy__Transaction_Item_Type_Config__mdt> getPrepaymentItemTypeConfigs(){

        Map<String, reduivy__Transaction_Item_Type_Config__mdt> trnItemTypeConfigsMap = new Map<String, reduivy__Transaction_Item_Type_Config__mdt>();
        if(prepaymentItemTypeConfigs == null) {

            for(reduivy__Transaction_Item_Type_Config__mdt trnItemType : reduivy__Transaction_Item_Type_Config__mdt.getAll().values()) {
                if(trnItemType.reduivy__Active__c && trnItemType.reduivy__Support_Prepayment_Conversion__c) {
                    trnItemTypeConfigsMap.put(trnItemType.reduivy__Item_Type__c, trnItemType);
                }
            }
        }

        return trnItemTypeConfigsMap;
    }
	
}