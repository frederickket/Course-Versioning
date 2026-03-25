/**
 * @author      WDCi (Xirouh)
 * @date        June 2024
 * @group       Object Helper
 * @description 
 * @changehistory
 * ISS-001978 24-06-2024  Xirouh - new class
 */
global inherited sharing class INQ_Helper implements SObject_Helper {

    /**
     * @description Status Type - Draft
     */
    public static final String STATUS_TYPE_DRAFT = 'Draft';

    /**
     * @description Status Type - Ready To Sync
     */
    public static final String STATUS_TYPE_READY_TO_SYNC = 'Ready To Sync';

    /**
     * @description Status Type - Sync Succeeded
     */
    public static final String STATUS_TYPE_SYNC_SUCCEEDED = 'Sync Succeeded';

    /**
     * @description Status Type - Sync Failed
     */
    public static final String STATUS_TYPE_SYNC_FAILED = 'Sync Failed';

    /**
     * @description Target System Type - External Portal
     */
    public static final String TARGET_SYSTEM_TYPE_EXT_PORTAL = 'External Portal';

    /**
     * @description Action Type - insert
     */
    public static final String ACTION_TYPE_INSERT = 'Insert';

    /**
     * @description Action Type - update
     */
    public static final String ACTION_TYPE_UPDATE = 'Update';

    /**
     * @description Action Type - delete
     */
    public static final String ACTION_TYPE_DELETE = 'Delete';

    /**
     * @description Action Type - undelete
     */
    public static final String ACTION_TYPE_UNDELETE = 'Undelete';

    /**
     * @description Response Msg when endpoint not found
     */
    public static final String ENDPOINT_NOT_FOUND = Label.Endpoint_Not_Found;

    /**
     * @description Error/Response Msg when record not found
     */
    public static final String RECORD_NOT_FOUND = Label.Record_Not_Found;

    /**
     * @description Error/Response Msg when bad response message returned from callout
     */
    public static final String BAD_RESPONSE_MSG = Label.Bad_response_from_the_callout;

    /**
     * @description Error/Response Msg when returned status code not in the list of success code list
     */
    public static final String SUCCESS_CODE_NOT_IN_LIST = Label.Success_Code_Not_In_List;

    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Integration_Queue__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Integration_Queue__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Integration_Queue__c.getName();
    }

    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Integration_Queue__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }

    /**
     * @description Add the Integration Queue records
     * @param actionType
     * @param sobjResult
     * @param sObj
     * @param status
     * @param targetSystem
     * @return reduivy__Integration_Queue__c
     */
    public static reduivy__Integration_Queue__c addIntegrationQueue (String actionType, Schema.DescribeSObjectResult sobjResult, SObject sObj, String status, String targetSystem) {
                
        Map<String, Object> payloadMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(sObj));
        
        if(actionType == INQ_Helper.ACTION_TYPE_DELETE) {
            payloadMap.put('IsDeleted', true);
        }
        
        String modifiedPayload = JSON.serialize(payloadMap);
        String payload1;
        String payload2 = null;

        Integer payloadFieldLength = Schema.SObjectType.reduivy__Integration_Queue__c.fields.reduivy__Payload1__c.getLength();

        if (modifiedPayload.length() > payloadFieldLength) {
            payload1 = modifiedPayload.left(payloadFieldLength);
            payload2 = modifiedPayload.mid(payloadFieldLength, modifiedPayload.length() - payloadFieldLength);
        } else {
            payload1 = modifiedPayload;
        }

        reduivy__Integration_Queue__c newINQ = new reduivy__Integration_Queue__c(
            reduivy__Action_Type__c = actionType,
            reduivy__Object_Type__c = sobjResult.getName(),
            reduivy__Status__c = status,
            reduivy__Target_System__c = targetSystem,
            reduivy__Payload1__c = payload1,
            reduivy__Payload2__c = payload2,
            reduivy__Object_Id__c = sObj.Id
        );

        return newINQ;
    }

    /**
     * @description List of reduivy__Integration_Queue_Configuration__mdt
     */
    private static List<reduivy__Integration_Queue_Configuration__mdt> inqConfigs;

    /**
     * @description get all reduivy__Integration_Queue_Configuration__mdt
     * @return List<reduivy__Integration_Queue_Configuration__mdt>
     */
    public static List<reduivy__Integration_Queue_Configuration__mdt> getIntegrationQueueConfigs() {
        
        if (inqConfigs == null) {
            //Get all configs
            inqConfigs = reduivy__Integration_Queue_Configuration__mdt.getAll().values();
        }
        
        return inqConfigs;
    }

    /**
     * @description get reduivy__Integration_Queue_Configuration__mdt 
     * @return List<reduivy__Integration_Queue_Configuration__mdt>
     */
    public static List<reduivy__Integration_Queue_Configuration__mdt> getIntegrationQueueConfigsByObjectTypeAndHttpMethod(String objectType, String httpMethod) {
        List<reduivy__Integration_Queue_Configuration__mdt> inqConfigsByObjectTypeAndHttpMethod = new List<reduivy__Integration_Queue_Configuration__mdt>();

        for (reduivy__Integration_Queue_Configuration__mdt inq : getIntegrationQueueConfigs()) {
            if (inq.reduivy__Object_Type__c == objectType && inq.reduivy__Http_Method__c == httpMethod && inq.reduivy__Active__c) {
                inqConfigsByObjectTypeAndHttpMethod.add(inq);
            }
        }

        return inqConfigsByObjectTypeAndHttpMethod;
    }
}