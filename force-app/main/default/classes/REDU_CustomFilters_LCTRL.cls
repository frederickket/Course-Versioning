/**
 * @author      WDCi (Lean)
 * @date        Oct 2023
 * @group       Custom Filter
 * @description Controller for custom filter
 * @changehistory
 * ISS-001752 28-10-2023 Lean - new class
 * ISS-002505 03-06-2025 XW - moved QueryBinder generation from here to OBJ class
 */
public with sharing class REDU_CustomFilters_LCTRL {
    static final List<Schema.DisplayType> supportedDisplayType = new List<Schema.DisplayType>{
        Schema.DisplayType.DATE,
        Schema.DisplayType.DATETIME,
        Schema.DisplayType.BOOLEAN,
        Schema.DisplayType.DOUBLE,
        Schema.DisplayType.INTEGER,
        Schema.DisplayType.PERCENT,
        Schema.DisplayType.CURRENCY,
        Schema.DisplayType.REFERENCE,
        Schema.DisplayType.ID,
        Schema.DisplayType.PICKLIST,
        Schema.DisplayType.MULTIPICKLIST,
        Schema.DisplayType.STRING,
        Schema.DisplayType.URL,
        Schema.DisplayType.EMAIL
    };
    
    /**
     * @description Initiate custom filter configs based on the provided record id, object type and mapping
     * @param sourceRecordId Source record id to retrieve the default value
     * @param sourceObjectType Target object API name
     * @param targetObjectType Target object API name
     * @param customFilterConfigus The minimum custom filter configs JSON serialized string that contains mapping
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse initCustomFilterConfigs(String sourceRecordId, String sourceObjectType, String targetObjectType, String customFilterConfigs, Boolean includeNoneOption){
        try {
            if (String.isBlank(targetObjectType) || String.isBlank(customFilterConfigs)) {
                return null;
            }

            Schema.DescribeSObjectResult dsr = REDU_Metadata_UTIL.describeSObject(targetObjectType);
            Map<String, Schema.SObjectField> fieldsMap = dsr.fields.getMap();

            Set<String> queryFields = new Set<String>();

            List<REDU_CustomFilter_OBJ> customFilters = (List<REDU_CustomFilter_OBJ>) JSON.deserialize(customFilterConfigs, List<REDU_CustomFilter_OBJ>.class);
            Decimal counter = 0;

            for (REDU_CustomFilter_OBJ cf : customFilters) {
                cf.seq = counter;
                counter ++;
                
                if (String.isNotBlank(cf.mapping)) {
                    List<String> mappingInfo = cf.mapping.split('=');

                    if (mappingInfo.isEmpty() || mappingInfo.size() != 2) {
                        throw new REDU_ApplicationException(Label.CustomFilter_Invalid_Mapping);
                    } else if (!fieldsMap.containsKey(mappingInfo.get(1).toLowerCase())) {
                        throw new REDU_ApplicationException(String.format(Label.CustomFilter_Invalid_Field, new List<String>{mappingInfo.get(1), targetObjectType}));
                    }

                    String sourceFieldName = mappingInfo.get(0);
                    String targetFieldName = mappingInfo.get(1);
                    queryFields.add(sourceFieldName);

                    Schema.DescribeFieldResult targetDfr = fieldsMap.get(targetFieldName.toLowerCase()).getDescribe();
                    Schema.DisplayType fieldDisplayType = targetDfr.getType();

                    cf.sourceFieldName = sourceFieldName;
                    cf.targetObjectType = targetObjectType;
                    cf.targetFieldType = fieldDisplayType.name();
                    cf.targetSoapFieldType = targetDfr.getSoapType().name();
                    cf.targetFieldName = targetFieldName;

                    
                    if (targetDfr.isFilterable()) {
                        if(!supportedDisplayType.contains(fieldDisplayType)) {
                            throw REDU_Exception_UTIL.auraException(String.format(Label.Unsupported_Field_Type, new List<String>{fieldDisplayType.name(), targetDfr.getLabel()}));
                        }
                    } else {
                        throw REDU_Exception_UTIL.auraException(String.format(Label.Unsupported_Field_Type, new List<String>{fieldDisplayType.name(), targetDfr.getLabel()}));
                    }

                    //set the picklist option
                    if (fieldDisplayType == Schema.DisplayType.MULTIPICKLIST || fieldDisplayType == Schema.DisplayType.PICKLIST) {
                        cf.picklistOptions = new List<REDU_PicklistOption_OBJ>();

                        if (fieldDisplayType == Schema.DisplayType.PICKLIST && includeNoneOption) {
                            cf.picklistOptions.add(new REDU_PicklistOption_OBJ(Label.Picklist_Option_None, null, false));
                        }

                        for (Schema.PicklistEntry ple : targetDfr.getPicklistValues()) {
                            if (ple.isActive()) {
                                cf.picklistOptions.add(new REDU_PicklistOption_OBJ(ple.getLabel(), ple.getValue(), false));
                            }
                        }
                    }

                    //set the label if not defined
                    if (String.isBlank(cf.label)) {
                        cf.label = targetDfr.getLabel();
                    }

                } else {
                    throw new REDU_ApplicationException(Label.CustomFilter_Missing_Mapping);
                }
            }

            if (!queryFields.isEmpty() && String.isNotBlank(sourceRecordId)) {
                Id convertedSourceRecordId = Id.valueOf(sourceRecordId);
                
                String sourceObjectTypeFromId = convertedSourceRecordId.getSobjectType().getDescribe(SObjectDescribeOptions.DEFERRED).getName();

                Map<String, Object> objectBindParams = new Map<String, Object>{
                    'recordId' => convertedSourceRecordId
                };

                String objectSoqlTemplate = 'SELECT {0} FROM {1} WHERE Id =: recordId LIMIT 1';
                String objectSoql = String.format(objectSoqlTemplate, new List<String>{String.join(queryFields, ', '), sourceObjectTypeFromId});
                
                for (SObject sobj : Database.queryWithBinds(objectSoql, objectBindParams, AccessLevel.USER_MODE)) {
                    for (REDU_CustomFilter_OBJ cf : customFilters) {
                        if (cf.sourceSobj == null) {
                            //skip the assignment if the customfilter already has existing sourceSobj to avoid overwriting when relaunching the customFilters component
                            cf.sourceSobj = sobj;
                        }
                    }
                }
            } else if (String.isNotBlank(sourceObjectType)) {
                Schema.SObjectType sobjType  = REDU_Metadata_UTIL.getSObjectType(sourceObjectType);
                
                for (REDU_CustomFilter_OBJ cf : customFilters) {
                    if (cf.sourceSobj == null) {
                        //skip the assignment if the customfilter already has existing sourceSobj to avoid overwriting when relaunching the customFilters component
                        cf.sourceSobj = sobjType.newSObject();
                    }                    
                }
            }

            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(customFilters));

        } catch (QueryException qex) {

            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {

            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

}