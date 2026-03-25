/**
 * @author      WDCi (XW)
 * @date        May 2024
 * @group       
 * @description The chatbot component that will be used in Utility bar
 * @changehistory
 * ISS-001916 20-05-2024 name - Chatbot
 */
public with sharing class REDU_ChatbotUtilityBar_LCTRL {
    
	@AuraEnabled(cacheable = true)
    public static REDU_LightningResponse getObjectApiName(Id recordId){
        try {
            String name = recordId.getSobjectType().getDescribe(SObjectDescribeOptions.DEFERRED).getName();
            REDU_LightningResponse response = new REDU_LightningResponse(true, 'success',  name);
            return response;
        }
        catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } 
         catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }
}