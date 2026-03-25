/**
 * @author      WDCi (Xirouh)
 * @date        June 2024
 * @group       
 * @description ISS-001978 - Execute callout for data pass from INQ_ExternalPortalSync_EXE
 * @changehistory
 * ISS-001978 31-06-2024 Xirouh- new class
 */
public inherited sharing class INQ_ExternalPortalSync_QUEUE implements Queueable, Database.AllowsCallouts {
    public Set<Id> inqIds;
    public List<List<Id>> inqIdsList;
	
    /**
     * @description to check the inqIds pass from the INQ_ExternalPortalSync_EXE
     * @param inqIdsList
     * @param enableLogging
     */
    public INQ_ExternalPortalSync_QUEUE(List<List<Id>> inqIdsList) {
        
        if (inqIdsList == null || inqIdsList.isEmpty()) {
            this.inqIds = new Set<Id>();
        } else {
            this.inqIds = new Set<Id>(inqIdsList.get(0));

            inqIdsList.remove(0);
            this.inqIdsList = inqIdsList;
        }

        REDU_Logging_UTIL.debug('INQ_ExternalPortalSync_QUEUE', inqIdsList);
    }

    public void execute(QueueableContext queueableContext) {
        Set<String> queryFields = new Set<String>{
            'Id',
            'reduivy__Action_Type__c',
            'reduivy__Object_Id__c',
            'reduivy__Object_Type__c',
            'reduivy__Payload1__c',
            'reduivy__Payload2__c',
            'reduivy__Status__c'
        };

        Map<String, Object> bindParams = new Map<String, Object>{
            'id' => inqIds
        };

        String soqlQuery = 'SELECT ' + String.join(queryFields, ', ') + 
            ' FROM reduivy__Integration_Queue__c ' +
            ' WHERE Id IN : id ' + 
            ' ORDER By CreatedDate ASC';
        
        Map<String, Set<String>> inqObjectFieldsFls = new Map<String, Set<String>>();
        inqObjectFieldsFls.put(INQ_Helper.getApiName(), queryFields);

        List<reduivy__Integration_Queue__c> inqRecords = REDU_SystemMode_UTIL.doQuery(soqlQuery, bindParams, inqObjectFieldsFls);
        
        if (!inqRecords.isEmpty()) {
            executeCalloutSync(inqRecords);
        }
        
        if (!Test.isRunningTest() && this.inqIdsList != null && !this.inqIdsList.isEmpty()) {
            INQ_ExternalPortalSync_QUEUE queueJob = new INQ_ExternalPortalSync_QUEUE(this.inqIdsList);
            System.enqueueJob(queueJob);
        }
    }

    /**
     * @description to structure the data pass to the doCallout method
     * @param inqRecords
     */
    public void executeCalloutSync(List<reduivy__Integration_Queue__c> inqRecords) {    
        List<String> payloads = new List<String>();
        List<Id> Ids = new List<Id>();
        List<reduivy__Integration_Queue__c> inqList = new List<reduivy__Integration_Queue__c>();
        String httpMethod = '';
        String objectType = '';
    
        for (reduivy__Integration_Queue__c record : inqRecords) {
            Ids.add(record.Id);
            String combinedPayload1And2 = record.reduivy__Payload1__c;

            if (record.reduivy__Payload2__c != null) {
                combinedPayload1And2 += record.reduivy__Payload2__c;
            }

            //We assume that it wont be combination of object type and http method
            if (record.reduivy__Action_Type__c == INQ_Helper.ACTION_TYPE_UPDATE || record.reduivy__Action_Type__c == INQ_Helper.ACTION_TYPE_DELETE) {
                httpMethod = 'PATCH';
            } else if (record.reduivy__Action_Type__c == INQ_Helper.ACTION_TYPE_INSERT || record.reduivy__Action_Type__c == INQ_Helper.ACTION_TYPE_UNDELETE) {
                httpMethod = 'POST';
            }

            payloads.add(combinedPayload1And2);
            inqList.add(record);
            objectType = record.reduivy__Object_Type__c;
        }
    
        String combinedPayloadArray = JSON.serialize(payloads);

        doCallout(combinedPayloadArray, inqList, httpMethod, objectType);
    }

    /**
     * @description do callout to external portal
     * @param payloads
     * @param inqList
     * @param httpMethod
     * @param objectType
     */
    public static void doCallout(String payloads, List<reduivy__Integration_Queue__c> inqList, String httpMethod, String objectType) {
        HttpResponse res;
        List<reduivy__Integration_Queue__c> recordsToUpdate = new List<reduivy__Integration_Queue__c>();
        Map<Id, reduivy__Integration_Queue__c> sourceMap = new Map<Id, reduivy__Integration_Queue__c>();

        //To get the success status code list and named credential
        List<reduivy__Integration_Queue_Configuration__mdt> inqConfig = INQ_Helper.getIntegrationQueueConfigsByObjectTypeAndHttpMethod(objectType, httpMethod);

        if (!inqConfig.isEmpty()) {
            List<String> successStatusCodeList = inqConfig[0].reduivy__Success_Status_Code__c.split(';');

            try {
                HttpRequest req = new HttpRequest();
                req.setEndpoint('callout:' + inqConfig[0].reduivy__Named_Credentials__c + '/' + inqConfig[0].reduivy__Endpoint_URL__c);
                req.setMethod(httpMethod);
                req.setHeader('Content-Type', 'application/json');
                req.setBody(payloads);
        
                Http http = new Http();
                res = http.send(req);
                
                //if returned success code in the the success code list in inqconfig
                if (successStatusCodeList.contains(String.valueOf(res.getStatusCode()))) {
                    //Structure the returned json response body
                    Map<Id, REDU_IntegrationQueueReponse_OBJ> integrationResponses = new Map<Id, REDU_IntegrationQueueReponse_OBJ>();
                    List<REDU_IntegrationQueueReponse_OBJ> filterValues = (List<REDU_IntegrationQueueReponse_OBJ>) JSON.deserialize(res.getBody(), List<REDU_IntegrationQueueReponse_OBJ>.class);
                    
                    for (REDU_IntegrationQueueReponse_OBJ item : filterValues) {
                        integrationResponses.put(item.id, item);
                    }

                    for (reduivy__Integration_Queue__c record : inqList) {
                        if (integrationResponses.containsKey(record.reduivy__Object_Id__c)) {
                            Boolean success = integrationResponses.get(record.reduivy__Object_Id__c).success;

                            record.reduivy__Status__c = success ? INQ_Helper.STATUS_TYPE_SYNC_SUCCEEDED : INQ_Helper.STATUS_TYPE_SYNC_FAILED;
                            record.reduivy__Response_Message__c = JSON.serialize(integrationResponses.get(record.reduivy__Object_Id__c));

                            recordsToUpdate.add(record);
                        } else { //if the returned response id is not found in the inqList
                            record.reduivy__Response_Message__c = INQ_Helper.RECORD_NOT_FOUND + '\nResponse Body: \n' + res.getBody();
                            record.reduivy__Status__c = INQ_Helper.STATUS_TYPE_SYNC_FAILED;

                            recordsToUpdate.add(record);
                        }
                    }     
                } else { //if the returned status code is not in the success code list in inqconfig
                    for (reduivy__Integration_Queue__c record : inqList) {
                        record.reduivy__Status__c = INQ_Helper.STATUS_TYPE_SYNC_FAILED;
                        record.reduivy__Response_Message__c = INQ_Helper.SUCCESS_CODE_NOT_IN_LIST + '\nResponse Status Code: ' + res.getStatusCode();
                        recordsToUpdate.add(record);
                        sourceMap.put(record.Id, record);
                    }
                } 
            } catch (System.JSONException e) { //if the returned response body is not in correct json format
                for (reduivy__Integration_Queue__c record : inqList) {
                    record.reduivy__Status__c = INQ_Helper.STATUS_TYPE_SYNC_FAILED;
                    record.reduivy__Response_Message__c = INQ_Helper.BAD_RESPONSE_MSG + '\nResponse Body: \n' + res.getBody();
                    recordsToUpdate.add(record);
                    sourceMap.put(record.Id, record);
                }

                REDU_Logging_UTIL.logError(INQ_Helper.BAD_RESPONSE_MSG, 'INQ_ExternalPortalSync_QUEUE', 'reduivy__Integration_Queue__c', null, e.getMessage(), null);

            } catch (Exception exp) { //if the callout is failed 
                for (reduivy__Integration_Queue__c record : inqList) {
                    record.reduivy__Status__c = INQ_Helper.STATUS_TYPE_SYNC_FAILED;
                    record.reduivy__Response_Message__c = res != null && res.getBody() != null ? res.getBody() : exp.getMessage();
                    recordsToUpdate.add(record);
                    sourceMap.put(record.Id, record);
                }

                REDU_Logging_UTIL.logError('Exception during sync', 'INQ_ExternalPortalSync_QUEUE', 'reduivy__Integration_Queue__c', null, JSON.serialize(recordsToUpdate), exp);
            }
        } else { //if the inqconfig not found
            for (reduivy__Integration_Queue__c record : inqList) {
                record.reduivy__Status__c = INQ_Helper.STATUS_TYPE_SYNC_FAILED;
                record.reduivy__Response_Message__c = res != null && res.getBody() != null ? res.getBody() : INQ_Helper.ENDPOINT_NOT_FOUND;
                recordsToUpdate.add(record);
                sourceMap.put(record.Id, record);
            }
            REDU_Logging_UTIL.logError('Endpoint not found in custom metadata', 'INQ_ExternalPortalSync_QUEUE', 'reduivy__Integration_Queue__c', null, JSON.serialize(recordsToUpdate), null);
        }
        
        if(!recordsToUpdate.isEmpty()) {
            //Update system fields using system admin
            REDU_SystemMode_UTIL.doUpdate(recordsToUpdate, sourceMap, 'reduivy__Object_Id__c', false);
        }
    }
}