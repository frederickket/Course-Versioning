/**
 * @author      WDCi (XW)
 * @date        May 2024
 * @group       Continuing Education
 * @description Apex Controller for continuing education cart payment
 * @changehistory
 * ISS-001660 31-05-2024 XW - Created new cart payment
 * ISS-002510 29-07-2025 XW - remove behaviour to update transaction order to submitted
 */
public with sharing class REDU_ContinuingEduCartPayment_LCTRL{
    
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
     * @Description This method is used to find whether the order is company order or not based on the given contact id.
     */
    @AuraEnabled(cacheable = true)
    public static REDU_LightningResponse checkCompanyOrder(String contactId) {
        try{
            Boolean isCorporatePurchaser = false;
            Contact targetContact;
            if (String.isEmpty(contactId)){
                //the controller is part of short course feature license


                targetContact = CON_Helper.getCurrentLoggedInUserContact();

            } else {
                targetContact = [SELECT Id, 
                    Name, 
                    reduivy__Corporate_Purchaser__c
                    FROM Contact
                    WHERE Id = :contactId
                    WITH USER_MODE
                    LIMIT 1
                ];
            }

            if (targetContact != null){
                if (targetContact.reduivy__Corporate_Purchaser__c == true) {
                    isCorporatePurchaser = true;
                }
            }

            return new REDU_LightningResponse(true, String.valueOf(isCorporatePurchaser), null);

        } catch (QueryException qex){
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp){
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @Description This method is used to update account and draft values on transaction order.
     */
    @AuraEnabled(cacheable = false)
    public static REDU_LightningResponse updateCompanyOrder(String currentOrderId, String orderSubmittedStatus) {
        try{
            Boolean isAccountUpdated = false;

            List<reduivy__Transaction_Order__c> rioOrder = new List<reduivy__Transaction_Order__c>();
            if (String.isNotEmpty(currentOrderId)){
                rioOrder = [SELECT Id, 
                    reduivy__Account__c, 
                    reduivy__Status__c, 
                    reduivy__Contact__c
                    FROM reduivy__Transaction_Order__c
                    WHERE Id = :currentOrderId 
                    AND reduivy__Status__c IN :TRO_Helper.getDraftStatuses()
                    WITH USER_MODE
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];
            }

            if (!rioOrder.isEmpty()){
                Contact orderContact = [SELECT Id, 
                    Name, 
                    AccountId
                    FROM Contact
                    WHERE Id =: rioOrder[0].reduivy__Contact__c
                    WITH USER_MODE
                ];

                rioOrder[0].reduivy__Account__c = orderContact.AccountId != null ? orderContact.AccountId : null;
                List<reduivy__Transaction_Order__c> orderToupdate = new List<reduivy__Transaction_Order__c>{ rioOrder[0] };
                REDU_Database_UTIL.doUpdate(orderToUpdate);

                isAccountUpdated = true;
            } else {
                return new REDU_LightningResponse(true, REDU_LightningResponse.FAIL, String.format(Label.Invalid_Record_Id, new List<String>{currentOrderId}));
            }

            if (isAccountUpdated == true){
                return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, null);
            } else{
                return new REDU_LightningResponse(true, '', null);
            }

        } catch (QueryException qex){
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp){
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

}