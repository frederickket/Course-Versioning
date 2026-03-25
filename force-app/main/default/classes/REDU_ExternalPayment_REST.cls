/**
 * @author      WDCi (XW)
 * @date        Apr 2025
 * @group       External Payment
 * @description Create Transaction Payment after External Payment
 * @changehistory
 * ISS-002352 18-04-2025 XW - create new class
 */

@RestResource(urlMapping='/v1/ExternalPaymentService/*')
global with sharing class REDU_ExternalPayment_REST {
    
    /**
     * @description Contact Identifier for response, required
     */
    public static final String REQUEST_IDENTIFIER_CON = 'contactIdentifier';

    /**
     * @description Contact Identifier for transaction order, optional
     */
    public static final String REQUEST_IDENTIFIER_TRO = 'transactionOrderIdentifier';

    /**
     * @description Transaction payment object, required
     */
    public static final String REQUEST_TRP = 'transactionPayment';

    /**
     * @description Status code - OK - Transaction Payment updated
     */
    public static final Integer STATUS_CODE_OK = 200;

    /**
     * @description Status code - Created - Transaction Payment created
     */
    public static final Integer STATUS_CODE_CREATED = 201;

    /**
     * @description Status code - Bad Request - Missing/invalid Transaction Payment/Contact, or missing Transaction Payment Id on PUT
     */
    public static final Integer STATUS_CODE_BAD_REQUEST = 400;

    /**
     * @description Status code - Forbidden - Contact mismatch with transaction order
     */
    public static final Integer STATUS_CODE_FORBIDDEN = 403;

    /**
     * @description Status code - Not Found - Transaction Order/Contact not found
     */
    public static final Integer STATUS_CODE_NOT_FOUND = 404;

    /**
     * @description Status code - Internal Server Error - Record creation/update failure
     */
    public static final Integer STATUS_CODE_INTERNAL_SERVER_ERROR = 500;

    /**
     * @description Create a new Transaction Payment Record based on contactIdentifier and transactionOrderIdentifier
     * @return   REDU_RestResponse
     */
    @HttpPost
    global static REDU_RestResponse handlePostRequest(){
        SavePoint sp = Database.setSavepoint();
        try {
            RestRequest requestRaw = RestContext.request;
            REDU_Logging_UTIL.debug('requestRaw', requestRaw.requestBody.toString());
            ExternalPaymentWrapper request = (ExternalPaymentWrapper) JSON.deserialize(requestRaw.requestBody.toString(), ExternalPaymentWrapper.class);

            //return error if transaction payment is not set in request
            if(request.transactionPayment == null) {
                String errorMessage = String.format(Label.Missing_Required_Parameters, 
                    new List<String>{ REQUEST_TRP }
                );

                return setAndGetResponse(false, errorMessage, STATUS_CODE_BAD_REQUEST, null);
            }

            //handle contact and transaction order
            REDU_RestResponse response = handleGeneralRequest(request);
            if(response.isSuccess == false) {
                return response;
            }

            REDU_Database_UTIL.doInsert(new List<reduivy__Transaction_Payment__c>{request.transactionPayment});
            REDU_Logging_UTIL.debugJsonString('request.transactionPayment', request.transactionPayment);
            
            return setAndGetResponse(true, Label.Request_Completed_Successfully, STATUS_CODE_CREATED, String.valueOf(request.transactionPayment.Id));

        } catch (Exception exp) {
            Database.rollback(sp);
            return setAndGetResponse(false, exp.getMessage(), STATUS_CODE_INTERNAL_SERVER_ERROR, null);
        }
    }

    /**
     * @description Update an existing Transaction Payment Record
     * @return   REDU_RestResponse
     */
    @HttpPut
    global static REDU_RestResponse handlePutRequest(){
        SavePoint sp = Database.setSavepoint();
        try {
            RestRequest requestRaw = RestContext.request;
            REDU_Logging_UTIL.debug('requestRaw', requestRaw.requestBody.toString());
            ExternalPaymentWrapper request = (ExternalPaymentWrapper) JSON.deserialize(requestRaw.requestBody.toString(), ExternalPaymentWrapper.class);
            
            //handle transaction payment request
            if(request.transactionPayment == null || String.isBlank(request.transactionPayment.Id)) {
                String errorMessage;

                if(request.transactionPayment == null) {
                    errorMessage = String.format(Label.Missing_Required_Parameters, 
                        new List<String>{ REQUEST_TRP }
                    );
                } else {
                    errorMessage = String.format(Label.Transaction_Payment_Id_Not_Found_In_Request, 
                        new List<String>{ TRP_Helper.getObjectLabel() }
                    );
                }

                return setAndGetResponse(false, errorMessage, STATUS_CODE_BAD_REQUEST, null);
            }

            //handle contact and transaction order
            REDU_RestResponse response = handleGeneralRequest(request);
            if(response.isSuccess == false) {
                return response;
            }

            REDU_Database_UTIL.doUpdate(new List<reduivy__Transaction_Payment__c>{request.transactionPayment});
            REDU_Logging_UTIL.debugJsonString('request.transactionPayment', request.transactionPayment);

            return setAndGetResponse(true, Label.Request_Completed_Successfully, STATUS_CODE_OK, String.valueOf(request.transactionPayment.Id));

        } catch (Exception exp) {
            Database.rollback(sp);
            return setAndGetResponse(false, exp.getMessage(), STATUS_CODE_INTERNAL_SERVER_ERROR, null);
        }
    }

    /**
     * @description handle contact and transaction order request for PUT and POST
     * @param  request the extenal payment wrapper object that represent the requst
     * @return         
     */
    private static REDU_RestResponse handleGeneralRequest(ExternalPaymentWrapper request){
        REDU_RestResponse response = new REDU_RestResponse();
        response.isSuccess = true;
        
        Contact contact;
        //handle contact request
        if(String.isNotBlank(request.contactIdentifier)) {

            contact = queryContact(request.contactIdentifier);
            if(contact == null) {
                //return error if contact is not found
                String errorMessage = String.format(Label.Invalid_Record_Identifier_For_Object_Type, 
                    new List<String>{
                        request.contactIdentifier, CON_Helper.getObjectLabel()
                    }
                );

                return setAndGetResponse(false, errorMessage, STATUS_CODE_NOT_FOUND, null);
            }
            //set parent contact id to transaction payment if contact is found
            request.transactionPayment.reduivy__Contact__c = contact.Id;
        } else {
            //return error if contact identifier is not set (required)
            String errorMessage = String.format(Label.Missing_Required_Parameters, new List<String>{REQUEST_IDENTIFIER_CON});
            return setAndGetResponse(false, errorMessage, STATUS_CODE_BAD_REQUEST, null);
        }        

        //handle transaction order request
        reduivy__Transaction_Order__c transactionOrder;
        if(String.isNotBlank(request.transactionOrderIdentifier)) {
            transactionOrder = queryTransactionOrder(request.transactionOrderIdentifier);
            if(transactionOrder == null) {
                //return error if tro is not found
                String errorMessage = String.format(Label.Invalid_Record_Identifier_For_Object_Type, 
                    new List<String>{
                        request.transactionOrderIdentifier, TRO_Helper.getObjectLabel()
                    }
                );
                return setAndGetResponse(false, errorMessage, STATUS_CODE_NOT_FOUND, null);

            } else if(String.isNotBlank(transactionOrder.reduivy__Contact__c) && transactionOrder.reduivy__Contact__c != contact.Id) {
                //throw an error if transaction order's contact mismatch with the contact id
                String errorMessage = String.format(Label.Contact_Does_Not_Match_Transaction_Order_Contact, 
                    new List<String>{
                        CON_Helper.getObjectLabel(), contact.Id, TRO_Helper.getObjectLabel()
                    }
                );
                
                return setAndGetResponse(false, errorMessage, STATUS_CODE_FORBIDDEN, null);
            }

            //set parent transaction order id to transaction payment if transaction order is found
            request.transactionPayment.reduivy__Transaction_Order__c = transactionOrder.Id;
        }

        return response;
    }

    /**
     * @description query transaction order based on identifier
     */
    private static reduivy__Transaction_Order__c queryTransactionOrder(String identifier){
        reduivy__Transaction_Order__c transactionOrder = null;
 
        for(reduivy__Transaction_Order__c tro : [ SELECT Id,
            reduivy__Contact__c
            FROM reduivy__Transaction_Order__c
            WHERE Name = :identifier OR Id = :identifier
            WITH USER_MODE
            LIMIT 1
        ]) {
            transactionOrder = tro;
        }

        return transactionOrder;
    }

    /**
     * @description query transaction order based on identifier
     */
    private static Contact queryContact(String identifier){
        Contact contact = null;

        for(Contact con : [ SELECT Id
            FROM Contact
            WHERE Email = :identifier OR Id = :identifier
            WITH USER_MODE
            LIMIT 1
        ]) {
            contact = con;
        }

        return contact;
    }

    /**
     * @description set the status code and get the restResponse object
     * @param  isSuccess    true if is success or false
     * @param  message message
     * @param  statusCode   The status code (200/404/...)
     * @param  recordId     The record id of the created/updated transaction payment
     * @return              REDU_RestResponse
     */
    private static REDU_RestResponse setAndGetResponse(Boolean isSuccess, String message, Integer statusCode, String recordId){
        REDU_RestResponse response = new REDU_RestResponse();
        response.isSuccess = isSuccess;
        response.status = isSuccess ? REDU_RestResponse.SUCCESS : REDU_RestResponse.FAIL;
        response.message = message;
        response.recordId = recordId;
        RestContext.response.statusCode = statusCode;

        REDU_Logging_UTIL.debugJsonString('REDU_RestResponse.response', response);

        return response;
    }

    /**
     * @description Wrapper class to handle rest request
     */
    public class ExternalPaymentWrapper {
        public String transactionOrderIdentifier;
        public String contactIdentifier;
        public reduivy__Transaction_Payment__c transactionPayment;
    }

}