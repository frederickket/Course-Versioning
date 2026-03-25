/**
 * @author      WDCi (Lean)
 * @date        July 2024
 * @group       Object Helper
 * @description Study Voucher object helper class that contains the picklist option constants and object related methods
 * @changehistory
 * 
 */
global inherited sharing class SVO_Helper implements SObject_Helper {

    /**
     * @description Voucher Type - Percentage
     */
    public static final String VOUCHER_TYPE_PERCENTAGE = 'Percentage';

    /**
     * @description Voucher Type - Amount
     */
    public static final String VOUCHER_TYPE_AMOUNT = 'Amount';

    /**
     * @description Voucher Type - Quantity
     */
    public static final String VOUCHER_TYPE_QUANTITY = 'Quantity';

    /**
     * @description Status - Active
     */
    public static final String STATUS_ACTIVE = 'Active';

    /**
     * @description Applicable Item Types - Deposit
     */
    public static final String APPLICABLE_ITEM_TYPES_DEPOSIT = 'Deposit';

    /**
     * @description Applicable Item Types - Application
     */
    public static final String APPLICABLE_ITEM_TYPES_APPLICATION = 'Application';

    /**
     * @description Applicable Item Types - Tuition
     */
    public static final String APPLICABLE_ITEM_TYPES_TUITION = 'Tuition';

    /**
     * @description Applicable Item Types - Residential
     */
    public static final String APPLICABLE_ITEM_TYPES_RESIDENTIAL = 'Residential';

    /**
     * @description Applicable Item Types - Deposit
     */
    public static final String APPLICABLE_ITEM_TYPES_MISCELLANEOUS = 'Miscellaneous';

    /**
     * @description Apply As - Order Line Discount
     */
    public static final String APPLY_AS_ORDER_LINE = 'Order Line Discount';

    /**
     * @description Apply As - Order Discount
     */
    public static final String APPLY_AS_ORDER = 'Order Discount';

    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Study_Voucher__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Study_Voucher__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Study_Voucher__c.getName();
    }
    
    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Study_Voucher__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }
}