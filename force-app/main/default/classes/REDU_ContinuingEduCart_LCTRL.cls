/**
 * @author      WDCi (XW)
 * @date        May 2024
 * @group       Continuing Education
 * @Description Apex Controller for continuing education cart
 * @changehistory
 * ISS-001660 28-05-2024 XW - Created new shopping cart
 * ISS-002104 04-12-2024 XW - update generateTableColMetadata param
 * ISS-002230 23-01-2025 XW - get picklist value label if field type is picklist
 * ISS-002393 15-04-2025 XW - moved some of the methods to REDU_ContinuingEduCartOrder_LCTRL
 * ISS-002393 15-04-2025 XW - get Agreed_To_Terms_And_Conditions__c from transaction order
 * ISS-002683 14-10-2025 Lean - Ensure query is done with filters
 * ISS-002746 27-11-2025 Lean - Standardize the CurrencyIsoCode detection
 * ISS-002793 10-02-2026 Lean - Support fully discounted order and custom criteria, hide order without line
 */
public with sharing class REDU_ContinuingEduCart_LCTRL{

    /**
     * @description Return community info
     */
    @AuraEnabled(cacheable = true)
    public static REDU_LightningResponse getCommunityInfo(){
        try {
            
            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(ORG_Helper.getCommunityInfo()));

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
     * @description Return list of unpaid or partially paid transaction orders
     * @param orderIds List of transaction order id
     * @param additionalFields Custom order fields
     * @param orderCustomCriteria Custom order query criteria
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getTransactionOrders(List<String> orderIds, String additionalFields, String orderCustomCriteria){
        try {

            User currentUser = USR_Helper.getCurrentUserInfo(UserInfo.getUserId());

            List<reduivy__Transaction_Order__c> troList = new List<reduivy__Transaction_Order__c>();

            //ISS-002683 skip if orderIds is empty and current user is not community user
            //for internal users, they should use the component on record page
            //for community users, they should use the component on any page and record page
            if (
                (orderIds != null && !orderIds.isEmpty()) || 
                String.isNotBlank(currentUser?.ContactId)
            ) {

                Set<String> svtFields = new Set<String> {
                    'Id',
                    'reduivy__Amount__c',
                    'reduivy__Study_Voucher__r.reduivy__Apply_As__c'
                };


                Set<String> troFields = new Set<String>{
                    'Id',
                    'Name',
                    'reduivy__Status__c',
                    'reduivy__Contact__c',
                    'reduivy__Payment_Status__c',
                    'reduivy__Total_Amount__c',
                    'reduivy__Total_Paid_Amount__c',
                    'reduivy__Total_Outstanding_Amount__c'
                };

                if (REDU_SObject_UTIL.hasCurrencyIsoCode(Schema.reduivy__Transaction_Order__c.getSObjectType())) {
                    troFields.add(REDU_SObject_UTIL.CURRENCYISOCODE_FIELD);
                }

                if(String.isNotBlank(additionalFields)) {
                    List<String> additionalFieldsList = additionalFields.split(REDU_List_UTIL.DELIMITER);
                    troFields.addAll(additionalFieldsList);
                }

                Map<String, Object> troBindParams = new Map<String, Object>();
                troBindParams.put('paymentStatuses', new Set<String>{TRO_Helper.PAYMENT_STATUS_NOTPAID, TRO_Helper.PAYMENT_STATUS_PARTIALLYPAID});
                troBindParams.put('orderStatuses', TRO_Helper.getDraftStatuses());
                troBindParams.put('svtConfirmedStatus', SVT_Helper.STATUS_CONFIRMED);
                troBindParams.put('orderlineType', TRL_Helper.TRANSACTION_TYPE_ORDERLINE);

                String troSoql = 'SELECT ' + String.join(troFields, ', ') + ', ( ' + 
                        ' SELECT ' + String.join(svtFields, ', ') + 
                        ' FROM reduivy__Study_Voucher_Transactions__r ' +
                        ' WHERE reduivy__Status__c = :svtConfirmedStatus ' +
                    ') ' +
                    ', (' +
                        ' SELECT Id, Name ' + 
                        ' FROM reduivy__Transaction_Line_Items__r ' +
                        ' WHERE reduivy__Transaction_Type__c =: orderlineType ' +
                        ' LIMIT 1 ' +
                    ')' +
                    ' FROM reduivy__Transaction_Order__c ';
                
                //ISS-002793 support custom criteria
                if (String.isBlank(orderCustomCriteria)) {
                    troSoql += ' WHERE (reduivy__Payment_Status__c IN: paymentStatuses ' +
                    ' OR reduivy__Status__c IN: orderStatuses) ';
                } else {
                    troSoql += ' WHERE (' + orderCustomCriteria + ')';
                }

                // we still restrict by order id or contact id regardless of the criteria above
                if (orderIds != null && !orderIds.isEmpty()){
                    //get by order id if available
                    troBindParams.put('orderIds', orderIds);
                    troSoql += ' AND Id IN: orderIds ';

                } else if (String.isNotEmpty(currentUser.ContactId)) {
                    //get by contact
                    troBindParams.put('contactId', currentUser.ContactId);
                    troSoql += ' AND reduivy__Contact__c =: contactId ';
                }

                troSoql += ' ORDER BY CreatedDate ASC';
                
                for (reduivy__Transaction_Order__c tro : (List<reduivy__Transaction_Order__c>) Database.queryWithBinds(troSoql, troBindParams, AccessLevel.USER_MODE)) {
                    // ISS-002793 There could be draft without order line, we won't show them
                    Boolean hasOrderLine = false;
                    for (reduivy__Transaction_Line_Item__c tli : tro.reduivy__Transaction_Line_Items__r) {
                        hasOrderLine = true;
                    }

                    if (hasOrderLine) {
                        troList.add(tro);
                    }
                }
            }

            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(troList));
            return response;

        } catch (QueryException qex){
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp){
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

}