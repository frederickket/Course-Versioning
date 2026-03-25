/**
 * @author      WDCi (XW)
 * @date        Apr 2024
 * @group       Continuing Education
 * @description Apex Controller for continuing education cart order
 * @changehistory
 * ISS-002393 15-04-2025 XW - moved part of REDU_ContinuingEduCart_LCTRL code to here
 * ISS-002510 30-07-2025 XW - introduced distributeOrderDiscount
 * ISS-002495 23-09-2025 XW - support translation for long text field
 * ISS-002736 25-11-2025 XiRouh - added enableWrapText param
 * ISS-002793 10-02-2026 Lean - Support fully discounted order and custom criteria, hide order without line
 */

public with sharing class REDU_ContinuingEduCartOrder_LCTRL {

    public static final String RESPONSE_DEFAULT_CURRENCY = 'defaultCurrency';
    public static final String RESPONSE_TRL_ORDERLINE_RECORDS = 'records';
    public static final String RESPONSE_TRL_DISCOUNTENTRY_RECORDS = 'discountEntryRecords';
    public static final String RESPONSE_COLUMNS = 'columns';
    public static final String RESPONSE_IS_MUTLICURRENCY_ORG = 'isMultiCurrencyOrg';

    private static final List<String> CONFIRMED_STATUSES = TRO_Helper.getConfirmedStatuses();
    
    /**
     * @description This method is used to delete orderline and its related study credit record.
     * @param  transactionLineRecordId     List of Transaction Line Items id to delete
     * @param  isLastTransactionLineDelete true if this is the last liREDU_ContinuingEduCartOrder_LCTRLne item in the transaction order
     * @param  orderId                     id of the affected order
     * @return                             REDU_LightningResponse
     */
    @AuraEnabled
    public static REDU_LightningResponse deleteTransactionLine(String orderId, List<String> transactionLineIds){

        try{
            
            Map<Id, reduivy__Transaction_Line_Item__c> transactionLinesRecords = new Map<Id, reduivy__Transaction_Line_Item__c>();
            for(reduivy__Transaction_Line_Item__c trl : [SELECT Id, 
                reduivy__Transaction_Order__c
                FROM reduivy__Transaction_Line_Item__c
                WHERE reduivy__Transaction_Order__c =: orderId
                AND reduivy__Transaction_Type__c =: TRL_Helper.TRANSACTION_TYPE_ORDERLINE
                WITH USER_MODE
            ]){
                transactionLinesRecords.put(trl.Id, trl);
            }

            List<reduivy__Transaction_Line_Item__c> trlDeleteList = new List<reduivy__Transaction_Line_Item__c>();
            if (transactionLineIds != null && !transactionLineIds.isEmpty()){
                
                for (String trlId : transactionLineIds) {
                    if (transactionLinesRecords.containsKey(trlId)) {
                        trlDeleteList.add(transactionLinesRecords.get(trlId));

                        transactionLinesRecords.remove(trlId);
                    } else {
                        String errorMsg = String.format(Label.Invalid_Record_Id_For_Object_Type, new List<String>{trlId, TRL_Helper.getObjectLabel()});
                        throw new REDU_ApplicationException(errorMsg);
                    }
                }
            } else {
                trlDeleteList.addAll(transactionLinesRecords.values());
                transactionLinesRecords.clear();
            }

            //user need to be able to delete the record regardless of ownership
            if(!trlDeleteList.isEmpty()) {
                REDU_SystemMode_UTIL.doDelete(trlDeleteList);
            }

            //delete the transaction order if it doesn't have any line item anymore
            if (transactionLinesRecords.isEmpty()){

                reduivy__Transaction_Order__c orderToDelete = new reduivy__Transaction_Order__c(
                    Id = orderId
                );

                //user need to be able to delete the record regardless of ownership
                REDU_SystemMode_UTIL.doDelete(new List<reduivy__Transaction_Order__c>{ orderToDelete });
            }

            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, null);
            return response;
            
        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    
    /**
     * @description This method is used to fetch orderlines record.
     * @param  troId                  Transaction order Id to display, null or empty to fetch all draft order
     * @param  transactionLinesFields Semicolon seperated string, list of transaction line item fields to show on table
     * @return                        REDU_LightningResponse
     */
    @AuraEnabled(cacheable = true)
    public static REDU_LightningResponse fetchTransactionLines(String troId, String transactionLinesFields, String language, Boolean enableWrapText){
        try{

            if(String.isBlank(language)) {
                language = UserInfo.getLanguage();
            }

            //system fields needed for calculation
            Set<String> trlFields = new Set<String>{
                'reduivy__Quantity__c',
                'reduivy__Unit_Price__c',
                'reduivy__Discount__c',
                'reduivy__Transaction_Order__c',
                'reduivy__Subtotal__c', 
                'reduivy__Study_Voucher_Transaction__c',
                'reduivy__Offset_Line_Item__c',
                'reduivy__Transaction_Type__c',
                'reduivy__Total_Amount__c'
            };
            
            //add table fields
            if(String.isNotBlank(transactionLinesFields)) {
                List<String> trlTableFields = transactionLinesFields.split(REDU_List_UTIL.DELIMITER);
                trlFields.addAll(trlTableFields);
            }

            //add picklist label field
            Set<String> trlAdditionalFields = new Set<String>();
            Schema.SObjectType tlnSobjectType = Schema.reduivy__Transaction_Line_Item__c.getSObjectType();
            for(String field: trlFields) {
                Schema.DescribeFieldResult fieldDfr = REDU_Datatable_UTIL.getFieldDescribe(field, tlnSobjectType);
                if(fieldDfr.getType() == Schema.DisplayType.PICKLIST || fieldDfr.getType() == Schema.DisplayType.MULTIPICKLIST) {
                    trlAdditionalFields.add(REDU_Metadata_UTIL.getPicklistFieldLabelQuery(field));
                } else if(fieldDfr.getType() == Schema.DisplayType.REFERENCE) {
                    trlAdditionalFields.add(REDU_Metadata_UTIL.getReferenceFieldForQuery(field, true));
                }
            }
            
            trlFields.addAll(trlAdditionalFields);
            trlFields.add('reduivy__Study_Voucher_Transaction__r.reduivy__Study_Voucher__r.reduivy__Apply_As__c');
            trlFields.add('reduivy__Study_Voucher_Transaction__r.reduivy__Amount__c');

            Map<String, Object> trlBindParams = new Map<String, Object>();
            trlBindParams.put('troId', troId);
            trlBindParams.put('orderlineType', TRL_Helper.TRANSACTION_TYPE_ORDERLINE);
            trlBindParams.put('discountType', TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY);

            String trlSoql = 'SELECT ' + String.join(trlFields, ',') +
                ' FROM reduivy__Transaction_Line_Item__c ' +
                ' WHERE reduivy__Transaction_Order__c =: troId ' +
                ' AND reduivy__Transaction_Type__c IN (:orderlineType, :discountType) ' + 
                ' ORDER BY CreatedDate ASC, Name ASC';

            List<reduivy__Transaction_Line_Item__c> trlOrderLineList = new List<reduivy__Transaction_Line_Item__c>();
            List<reduivy__Transaction_Line_Item__c> trlDiscountEntryList = new List<reduivy__Transaction_Line_Item__c>();
            for(reduivy__Transaction_Line_Item__c trl : (List<reduivy__Transaction_Line_Item__c>) Database.queryWithBinds(trlSoql, trlBindParams, Accesslevel.USER_MODE)){
                if(trl.reduivy__Transaction_Type__c == TRL_Helper.TRANSACTION_TYPE_DISCOUNTENTRY) {
                    trlDiscountEntryList.add(trl);
                } else if (trl.reduivy__Transaction_Type__c == TRL_Helper.TRANSACTION_TYPE_ORDERLINE) {
                    trlOrderLineList.add(trl);
                }
            }

            Map<String, Object> responseJson = new Map<String, Object>();

            String transactionLineItemsJson = generateResponseJson(transactionLinesFields, trlOrderLineList, trlDiscountEntryList, language, enableWrapText);

            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, transactionLineItemsJson);
            return response;

        } catch (QueryException qex){
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp){
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description This method is used to update transaction order and its related transaction line items.
     * @param  transactionOrderId       transaction order id
     * @param  transactionLineItemsJsonStr    transaction line items array in JSON format
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable = false)
    public static REDU_LightningResponse updateTransactionFeeLine(String transactionOrderId, String transactionLineItemJsonStr){
        try{

            reduivy__Transaction_Line_Item__c transactionLineItem = (reduivy__Transaction_Line_Item__c)JSON.deserialize(transactionLineItemJsonStr, reduivy__Transaction_Line_Item__c.class);
            if (transactionLineItem != null){
                
                reduivy__Transaction_Line_Item__c updateLine = new reduivy__Transaction_Line_Item__c();
                updateLine.Id = transactionLineItem.Id;
                updateLine.reduivy__Quantity__c = transactionLineItem.reduivy__Quantity__c;
                

                REDU_Database_UTIL.doUpdate(new List<reduivy__Transaction_Line_Item__c>{updateLine});
            }

            REDU_LightningResponse response = new REDU_LightningResponse(true, '', JSON.serialize(transactionLineItem));
            return response;

        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description create JSON that can be use to display the fields on datatable in LWC
     * @param  fieldNamesString            Semicolon seperated string, list of transaction line item fields to show on datatable
     * @param  transactionLineRecords      List of transaction Line Item records where transaction order = current trancation order
     * @return                             String which can be used to display on the datatable
     */
    private static String generateResponseJson(String fieldNamesString, List<Sobject> orderLineRecords, List<Sobject> discountEntryRecords, String language, Boolean enableWrapText){
        JSONGenerator gen = JSON.createGenerator(true);
        JSONGenerator refLinkGen = JSON.createGenerator(true);
        REDU_Datatable_UTIL.generateRefLinksMetadata(refLinkGen, TRL_Helper.getObjectType(), fieldNamesString);

        gen.writeStartObject();
            gen.writeObjectField(RESPONSE_TRL_ORDERLINE_RECORDS, orderLineRecords);
            gen.writeObjectField(RESPONSE_TRL_DISCOUNTENTRY_RECORDS, discountEntryRecords);
            gen.writeStringField(RESPONSE_DEFAULT_CURRENCY, UserInfo.getDefaultCurrency());
            gen.writeBooleanField(RESPONSE_IS_MUTLICURRENCY_ORG, ORG_Helper.isMultiCurrenciesOrg());
            gen.writeObjectField(ORG_Helper.SITE_PATH_PREFIX_PARAM, ORG_Helper.getCommunityInfo().get(ORG_Helper.SITE_PATH_PREFIX_PARAM));
            Map<String, Object> translationInfo = REDU_TranslationManager.getTranslationInfo(TRL_Helper.getApiName(), orderLineRecords, fieldNamesString.split(REDU_List_UTIL.DELIMITER), language);
            gen.writeObjectField(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM, translationInfo);
            gen.writeFieldName(RESPONSE_COLUMNS);
            REDU_Datatable_UTIL.generateTableColMetadata(gen, TRL_Helper.getObjectType(), fieldNamesString, false, null, false, null, false, enableWrapText); //ISS-002104
            gen.writeObjectField(REDU_Datatable_UTIL.REFLINKS_PARAM, JSON.deserializeUntyped(refLinkGen.getAsString()));

        gen.writeEndObject();
        return gen.getAsString();
    }

    /**
     * @description get TRO statuses
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getTransactionOrderStatuses(){
        try{
            //ISS-002793 return more status so that we can prevent users from editing draft order
            Map<String, List<String>> result = new Map<String, List<String>> {
                TRO_Helper.STATUS_TYPE_DRAFT => TRO_Helper.getDraftStatuses(),
                TRO_Helper.STATUS_TYPE_CONFIRMED => TRO_Helper.getConfirmedStatuses(),
                TRO_Helper.STATUS_TYPE_VOID => TRO_Helper.getVoidStatuses(),
                TRO_Helper.STATUS_TYPE_SUBMITTED => TRO_Helper.getSubmittedStatuses(),
                TRO_Helper.STATUS_TYPE_REFUNDED => TRO_Helper.getRefundedStatuses()
            };

            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(result));
            return response;
        } catch (QueryException qex){
        String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
        throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp){
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description distribute the order discount from study voucher transaction to discount entry line item
     * @param  troId transaction order id
     * @return       
     */
    @AuraEnabled
    public static REDU_LightningResponse distributeOrderDiscount(String troId){
        try {
            
            //update the status to confirmed
            List<reduivy__Transaction_Order__c> troList = new List<reduivy__Transaction_Order__c>();
            for(reduivy__Transaction_Order__c tro : [
                SELECT Id, 
                reduivy__Status__c
                FROM reduivy__Transaction_Order__c
                WHERE Id = :troId
                WITH USER_MODE
                LIMIT 1
            ]) {
                troList.add(tro);
            }
                
            if(!troList.isEmpty() && !CONFIRMED_STATUSES.contains(troList[0].reduivy__Status__c)) {
                TRO_Helper.distributeOrderDiscount(new Set<Id> {troId});
                troList[0].reduivy__Status__c = CONFIRMED_STATUSES[0];
                REDU_Database_UTIL.doUpdate(troList);
            }
                
            return new REDU_LightningResponse(true, 'success', JSON.serialize(troList));

        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp){
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description get the transaction order with the record id
     * @param  troId 
     * @return       
     */
    @AuraEnabled
    public static REDU_LightningResponse getTransactionOrder(String troId){
        try {
            reduivy__Transaction_Order__c tro;
            if(String.isNotBlank(troId)) {

                for(reduivy__Transaction_Order__c tempTro : [
                    SELECT Id, 
                    reduivy__Agreed_To_Terms_And_Conditions__c
                    FROM reduivy__Transaction_Order__c
                    WHERE Id = :troId
                    WITH USER_MODE
                    LIMIT 1
                ]) {
                    tro = tempTro;
                }
            }
            
            return new REDU_LightningResponse(true, 'success', JSON.serialize(tro));

        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);
        } catch (Exception exp){
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

}