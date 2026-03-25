/**
 * @author      WDCi (Jordan)
 * @date        Feb 2024
 * @group       Continuing Education
 * @description Controller for continuingEduHeader
 * @changehistory
 * ISS-001846 22-02-2024 Jordan - new class
 */
public with sharing class REDU_ContinuingEduDetail_LCTRL {
    
    /**
     * @description This method is used to get {Label and fieldApi Names} from field api names inputed by user.
     * @param sObjectName
     * @param recordId
     * @param fieldNames
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getObjectFields(String sObjectName, Id recordId, String fieldNames) {
        try {

            if (recordId != null && String.isBlank(sObjectName)) {
                sObjectName = recordId.getSobjectType().getDescribe(SObjectDescribeOptions.DEFERRED).getName();
            }

            List<REDU_DynamicFieldValue_OBJ> fieldsArray = new List<REDU_DynamicFieldValue_OBJ>();
            if(!String.isBlank(fieldNames)) {
                //To get all the fields defined in the field api names inputed by user.
                Schema.DescribeSObjectResult describeSObjectResultObj = REDU_Metadata_UTIL.describeSObject(sObjectName);
                Map<String,Schema.SObjectField> fieldMap = describeSObjectResultObj.fields.getMap();
                List<String> fields = fieldNames.toLowerCase().split(REDU_List_UTIL.DELIMITER);
                for(String eachField : fields) {
                    if(fieldMap.containsKey(eachField)) {
                        Schema.DescribeFieldResult dfr = fieldMap.get(eachField).getDescribe();
                        if (dfr.isAccessible()) {
                            REDU_DynamicFieldValue_OBJ eachObj = new REDU_DynamicFieldValue_OBJ();
                            eachObj.fieldName = dfr.getName();
                            eachObj.label = dfr.getLabel();
                            eachObj.objectName = sObjectName;

                            fieldsArray.add(eachObj);
                        }
                    }
                }
            }
            if(!fieldsArray.isEmpty()) {
                return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(fieldsArray));
            } else {
                return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, null);
            }
        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }
}