/**
 * @Author 		WDCi (Lean)
 * @Date 		Nov 2023
 * @group 		Study Plan
 * @Description Study plan hierarchy wizard
 * @changehistory
 * ISS-001617 10-11-2023 Lean - new component
 * ISS-002104 04-12-2024 XW - update generateTableColMetadata param
 * ISS-002152 06-11-2024 Jordan - Study Plan Wizard to support modification
 * ISS-002230 22-01-2025 XW - get picklist value label if field type is picklist
 * ISS-002330 24-03-2025 XW - query sps translation name if found
 * ISS-002495 23-09-2025 XW - support translation for long text field
 * ISS-002736 25-11-2025 XiRouh - added enableWrapText param
 * ISS-002746 27-11-2025 Lean - Standardize the CurrencyIsoCode detection
 */
public with sharing class REDU_StudyPlanUnitTable_LCTRL {
    
    /**
     * @description Get unit SPS table data
     * @param spsParentId
     * @param spsUnitTableFields
     * @param enableClickableRefField
     * @param hrefTargetType
     * @param isModeView
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getUnitTableData(Id spsParentId, String spsUnitTableFields, Boolean enableClickableRefField, String hrefTargetType, Boolean isModeView, String language, Boolean enableWrapText){
        
        Map<String, Object> responseJSON = new Map<String, Object>();

        try {

            language = String.isBlank(language) ? UserInfo.getLanguage() : language;
            if(String.isNotBlank(spsParentId) && String.isNotBlank(spsUnitTableFields)){

                SObjectType rootSObjectType = reduivy__Study_Plan_Structure__c.sObjectType;

                //Generate column metadata for datatable
                List<REDU_Datatable_UTIL.TableActionWrapper> tableActionList = new List<REDU_Datatable_UTIL.TableActionWrapper>();

                if (!isModeView) {
                    tableActionList.add(new REDU_Datatable_UTIL.TableActionWrapper(System.Label.Edit, REDU_StudyPlanHierarchy_LCTRL.EDIT_ACTION_TYPE));
                    tableActionList.add(new REDU_Datatable_UTIL.TableActionWrapper(System.Label.Delete, REDU_StudyPlanHierarchy_LCTRL.DELETE_ACTION_TYPE));
                }

                JSONGenerator jsonGen = JSON.createGenerator(true);
                REDU_Datatable_UTIL.generateTableColMetadata(jsonGen, rootSObjectType, spsUnitTableFields, false, tableActionList, enableClickableRefField, hrefTargetType, false, enableWrapText); //ISS-002104

                //Store list of fields that have ref to parent
                JSONGenerator tableFieldRefMetadata = JSON.createGenerator(true);
                REDU_Datatable_UTIL.generateRefLinksMetadata(tableFieldRefMetadata, rootSObjectType, spsUnitTableFields);
                
                Set<String> spsFields = new Set<String>{'Id', 'Name', SPS_Helper.getTranslationFieldNameForName()};

                for (String field : spsUnitTableFields.split(';')) {
                    Schema.DescribeFieldResult fieldDescribe = REDU_Datatable_UTIL.getFieldDescribe(field, rootSObjectType);
                    spsFields.add(field);

                    if(fieldDescribe.getType() == Schema.DisplayType.REFERENCE) {
                        spsFields.add(REDU_Metadata_UTIL.getReferenceFieldForQuery(field, true));
                    } else if(fieldDescribe.getType() == Schema.DisplayType.PICKLIST || fieldDescribe.getType() == Schema.DisplayType.MULTIPICKLIST) {
                        spsFields.add(REDU_Metadata_UTIL.getPicklistFieldLabelQuery(field));
                    }
                }

                if (REDU_SObject_UTIL.hasCurrencyIsoCode(rootSObjectType)) {
                    spsFields.add(REDU_SObject_UTIL.CURRENCYISOCODE_FIELD);
                }

                Map<String, Object> spsUnitBindParams = new Map<String, Object>{
                    'spsUnitRtId' => SPS_Helper.getUnitRecordTypeId(),
                    'parentId' => spsParentId
                };

                //Query IPS Units with related fields to be displayed in the datatable
                String spsQuery = 'SELECT ' + String.join(spsFields, ',') +
                    ' FROM reduivy__Study_Plan_Structure__c ' +
                    ' WHERE RecordTypeId =: spsUnitRtId ' +
                    ' AND reduivy__Parent_Study_Plan_Structure__c =: parentId ' +
                    ' ORDER BY reduivy__Sequence_Key__c ASC NULLS LAST ';

                List<reduivy__Study_Plan_Structure__c> spsChildUnits = new List<reduivy__Study_Plan_Structure__c>();
                for(reduivy__Study_Plan_Structure__c unitSps : (List<reduivy__Study_Plan_Structure__c>) Database.queryWithBinds(spsQuery, spsUnitBindParams, AccessLevel.USER_MODE)){
                    spsChildUnits.add(unitSps);
                }

                Map<String, Object> translationInfo = REDU_TranslationManager.getTranslationInfo(SPS_Helper.getApiName(), spsChildUnits, spsFields, language);
                
                responseJSON.put(REDU_Datatable_UTIL.RECORDS_PARAM, spsChildUnits);
                responseJSON.put(REDU_Datatable_UTIL.COLUMNS_PARAM, JSON.deserializeUntyped(jsonGen.getAsString()));
                responseJSON.put(REDU_Datatable_UTIL.REFLINKS_PARAM, JSON.deserializeUntyped(tableFieldRefMetadata.getAsString()));
                responseJSON.put(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM, translationInfo);
                responseJSON.put(REDU_Datatable_UTIL.SITE_PATH_PREFIX_PARAM, ORG_Helper.getCommunityInfo().get(ORG_Helper.SITE_PATH_PREFIX_PARAM));
            }

            
            REDU_Logging_UTIL.debugJsonString('responseJSON', responseJSON);

            return new REDU_LightningResponse(true, 'success', JSON.serialize(responseJSON));

        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }

    }
}