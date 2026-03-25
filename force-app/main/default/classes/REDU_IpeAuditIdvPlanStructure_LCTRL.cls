/**
 * @author      WDCi (VTan)
 * @date        Oct 2023
 * @group       Lightning Web Component
 * @description ISS-001753 Controller for ipeAudit lightning web component.
 * @changehistory
 * ISS-001753 23-10-2023 VTan - New class
 * ISS-002104 04-12-2024 XW - update generateTableColMetadata param
 * ISS-002230 22-01-2025 XW - get picklist value label if field type is picklist
 * ISS-002495 23-09-2025 XW - support translation for long text field
 * ISS-002736 25-11-2025 XiRouh - added enableWrapText param
 * ISS-002746 27-11-2025 Lean - Standardize the CurrencyIsoCode detection
 */
public with sharing class REDU_IpeAuditIdvPlanStructure_LCTRL {
    
    //For response
    public static final String GROUPDATA_PARAM = 'groupData';

    /**
     * @description Get list of the child IPS Groups or IPS Units related to the current ipsGroupId
     * @param ipsGroupId Individual Plan Structure (Group) Id
     * @param ipsUnitTableFields String of IPS Unit fields separated by semicolon (;)
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getIdvPlanStructureChildren (String ipsGroupId, String ipsUnitTableFields, Boolean enableClickableRefField, Boolean enableSetPrimaryIps, Boolean enableViewEnrollmentHistory, String hrefTargetType, String language, Boolean enableWrapText){

        Map<String, Object> responseJSON = new Map<String, Object>();

        try {
            language = String.isBlank(language) ? UserInfo.getLanguage() : language;
            List<reduivy__Individual_Plan_Structure__c> ipsChildGroups = new List<reduivy__Individual_Plan_Structure__c>();

            Set<Id> idvEnrollmentIds = new Set<Id>();
            Set<Id> ipsChildUnitIds = new Set<Id>();

            Id ispGroupRTID = IPS_Helper.getGroupRecordTypeId();
            Id ispUnitRTID = IPS_Helper.getUnitRecordTypeId();

            for (reduivy__Individual_Plan_Structure__c ipsChild : [SELECT Id, Name, reduivy__Category__c, reduivy__Sequence__c, RecordTypeId, reduivy__Individual_Enrollment__c
                FROM reduivy__Individual_Plan_Structure__c 
                WHERE reduivy__Parent_Plan_Structure__c =: ipsGroupId 
                WITH USER_MODE
                ORDER BY reduivy__Sequence_Key__c ASC NULLS LAST
            ]) {

                if(ipsChild.RecordTypeId == ispGroupRTID){

                    //Get list of IPS Groups
                    ipsChildGroups.add(ipsChild);
                }else if(ipsChild.RecordTypeId == ispUnitRTID){

                    //Get list of IPS Units
                    ipsChildUnitIds.add(ipsChild.Id);
                }
            }

            if(!ipsChildUnitIds.isEmpty()){

                Set<String> ipsUnitFields = new Set<String>{'Id', 'Name', 'reduivy__Individual_Enrollment__c', 'reduivy__Study_Plan_Structure__r.reduivy__Study_Unit__r.reduivy__Unit_Code__c', 'reduivy__Alternate_Study_Unit__r.reduivy__Unit_Code__c'};
                SObjectType rootSObjectType = reduivy__Individual_Plan_Structure__c.sObjectType;

                //Generate column metadata for datatable
                List<REDU_Datatable_UTIL.TableActionWrapper> tableActionList = new List<REDU_Datatable_UTIL.TableActionWrapper>();

                if(enableSetPrimaryIps){
                    tableActionList.add(new REDU_Datatable_UTIL.TableActionWrapper(System.Label.Set_as_Primary, 'Set_as_Primary'));
                }
                if(enableViewEnrollmentHistory){
                    tableActionList.add(new REDU_Datatable_UTIL.TableActionWrapper(System.Label.View_Individual_Enrollment_History, 'View_Individual_Enrollment_History'));
                }

                JSONGenerator tableColumnMetadata = JSON.createGenerator(true);
                REDU_Datatable_UTIL.generateTableColMetadata(tableColumnMetadata, rootSObjectType, ipsUnitTableFields, false, tableActionList, enableClickableRefField, hrefTargetType, false, enableWrapText); //ISS-002104

                //Store list of fields that have ref to parent
                JSONGenerator tableFieldRefMetadata = JSON.createGenerator(true);
                REDU_Datatable_UTIL.generateRefLinksMetadata(tableFieldRefMetadata, rootSObjectType, ipsUnitTableFields);
                
                if (String.isNotBlank(ipsUnitTableFields)) {
                    ipsUnitFields.addAll(ipsUnitTableFields.split(';'));
                }

                // Find the picklist field so that we add the toLabel() to the query as well
                Set<String> ipsUnitAdditionalFields = new Set<String>();
                for (String field : ipsUnitFields) {
                    Schema.DescribeFieldResult fieldDescribe = REDU_Datatable_UTIL.getFieldDescribe(field, rootSObjectType);

                    if(fieldDescribe.getType() == Schema.DisplayType.REFERENCE) {
                        ipsUnitAdditionalFields.add(REDU_Metadata_UTIL.getReferenceFieldForQuery(field, true));
                    } else if(fieldDescribe.getType() == Schema.DisplayType.PICKLIST || fieldDescribe.getType() == Schema.DisplayType.MULTIPICKLIST) {
                        ipsUnitAdditionalFields.add(REDU_Metadata_UTIL.getPicklistFieldLabelQuery(field));
                    }                 
                }

                ipsUnitFields.addAll(ipsUnitAdditionalFields);

                if (REDU_SObject_UTIL.hasCurrencyIsoCode(rootSObjectType)) {
                    ipsUnitFields.add(REDU_SObject_UTIL.CURRENCYISOCODE_FIELD);
                }

                Map<String, Object> ipsUnitBindParams = new Map<String, Object>{
                    'ipsChildUnitIds' => ipsChildUnitIds
                };

                //Query IPS Units with related fields to be displayed in the datatable
                String queryString = 'SELECT ' + String.join(ipsUnitFields, ',');
                queryString += ' FROM reduivy__Individual_Plan_Structure__c ';
                queryString += ' WHERE Id IN : ipsChildUnitIds';

                REDU_Logging_UTIL.debug('queryString', queryString);

                List<reduivy__Individual_Plan_Structure__c> ipsChildUnits = new List<reduivy__Individual_Plan_Structure__c>();
                for(reduivy__Individual_Plan_Structure__c ipsUnit : (List<reduivy__Individual_Plan_Structure__c>) Database.queryWithBinds(queryString, ipsUnitBindParams, AccessLevel.USER_MODE)){
                    ipsChildUnits.add(ipsUnit);
                }
                Map<String, Object> translationInfo = REDU_TranslationManager.getTranslationInfo(IPS_Helper.getApiName(), ipsChildUnits, ipsUnitTableFields.split(';'), language);

                responseJSON.put(REDU_Datatable_UTIL.RECORDS_PARAM, ipsChildUnits);
                responseJSON.put(REDU_Datatable_UTIL.COLUMNS_PARAM, JSON.deserializeUntyped(tableColumnMetadata.getAsString()));
                responseJSON.put(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM, translationInfo);
                responseJSON.put(REDU_Datatable_UTIL.REFLINKS_PARAM, JSON.deserializeUntyped(tableFieldRefMetadata.getAsString()));
                responseJSON.put(REDU_Datatable_UTIL.SITE_PATH_PREFIX_PARAM, ORG_Helper.getCommunityInfo().get(ORG_Helper.SITE_PATH_PREFIX_PARAM));
            }
 
            if(!ipsChildGroups.isEmpty()){
                responseJSON.put(GROUPDATA_PARAM, ipsChildGroups);
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

    /**
     * @description Set the Individual Plan Structure Unit as Primary
     * @param ipsUnitRecord Individual Plan Structure (Unit) record
     * @return REDU_LightningResponse
     */
    @AuraEnabled
    public static REDU_LightningResponse setPrimaryIpsUnit (String ipsUnitRecord){

        try {
            REDU_Logging_UTIL.debug('ipsUnitRecord', ipsUnitRecord);
            
            reduivy__Individual_Plan_Structure__c ipsUnit = (reduivy__Individual_Plan_Structure__c) JSON.deserialize(ipsUnitRecord, reduivy__Individual_Plan_Structure__c.class);

            if (ipsUnit == null || ipsUnit.Id == null) {
                throw new REDU_ApplicationException(Label.Error_Contact_Admin);
            }else{

                reduivy__Individual_Plan_Structure__c updateIpsUnit = [SELECT Id, 
                    reduivy__Primary__c 
                    FROM reduivy__Individual_Plan_Structure__c 
                    WHERE Id = :ipsUnit.Id
                    WITH USER_MODE
                ];

                if(!updateIpsUnit.reduivy__Primary__c){

                    updateIpsUnit.reduivy__Primary__c = true;

                    REDU_Database_UTIL.doUpdate(new List<reduivy__Individual_Plan_Structure__c>{updateIpsUnit});
                }
            }

            return new REDU_LightningResponse(true, 'success', JSON.serialize(new Set<Id>{ipsUnit.Id}));

        } catch (QueryException qex) {

            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {

            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }
}