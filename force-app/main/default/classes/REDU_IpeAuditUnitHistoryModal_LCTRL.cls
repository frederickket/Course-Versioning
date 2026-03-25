/**
 * @author      WDCi (VTan)
 * @date        Nov 2023
 * @group       Program Completion Wizard
 * @description ISS-001824 Controller for ipeAudit lightning web component.
 * @changehistory
 * ISS-001824 01-12-2023 VTan - Modal to display unit enrollment history in program completion wizard.
 * ISS-002104 04-12-2024 XW - update generateTableColMetadata param
 * ISS-002230 22-01-2025 XW - get picklist value label if field type is picklist
 * ISS-002365 27-03-2025 Lean - Standardize the ien ordering criteria
 * ISS-002495 23-09-2025 XW - support translation for long text field
 * ISS-002736 25-11-2025 XiRouh - added enableWrapText param
 * ISS-002746 27-11-2025 Lean - Standardize the CurrencyIsoCode detection
 * ISS-002743 09-12-2025 XiRouh - Updated to consider the IPF when querying the IEN history, and to display only IENs that are not in an open status
 */
public with sharing class REDU_IpeAuditUnitHistoryModal_LCTRL{

    private static final List<String> IEN_OPEN_STATUSES = IEN_Helper.getOpenStatuses();
    
	/**
     * @description Get list of the individual enrollments related to the study unit in selected ISP Unit
     * @param ipsUnitId Individual Plan Structure (Unit) Id
     * @param idvEnrollmentFields String of Individual Enrollment fields separated by semicolon (;)
     * @param enableClickableRefField Enable clickable on ref field
     * @param hrefTargetType href Target Type 
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getIdvEnrollmentHistory (String ipsUnitId, String idvEnrollmentFields, Boolean enableClickableRefField, String hrefTargetType, String language, Boolean enableWrapText){

        Map<String, Object> responseJSON = new Map<String, Object>();

        try {
            language = String.isBlank(language) ? UserInfo.getLanguage() : language;
            Set<Id> studyUnitIds = new Set<Id>();
            Set<Id> contactIds = new Set<Id>();
            Set<Id> ipfIds = new Set<Id>();

            //Get the required information for individual enrollment query
            for (reduivy__Individual_Plan_Structure__c ipsUnit : [SELECT Id, 
                Name, reduivy__Individual_Enrollment__c, 
                reduivy__Individual_Enrollment__r.reduivy__Target_Unit_Id__c, 
                reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c,
                reduivy__Individual_Program_Enrollment__r.reduivy__Individual_Academic_Profile__c,
                reduivy__Individual_Program_Enrollment__r.reduivy__Master_Enrollment__c,
                reduivy__Individual_Program_Enrollment__r.reduivy__Master_Enrollment__r.reduivy__Individual_Academic_Profile__c
                FROM reduivy__Individual_Plan_Structure__c 
                WHERE Id =: ipsUnitId 
                WITH USER_MODE
            ]) {
                Id academicProfileId = IPS_Helper.getIpfId(ipsUnit);

                if(ipsUnit.reduivy__Individual_Enrollment__c != null && 
                    String.isNotBlank(ipsUnit.reduivy__Individual_Enrollment__r.reduivy__Target_Unit_Id__c) && 
                    String.isNotBlank(academicProfileId)
                ){
                    studyUnitIds.add(ipsUnit.reduivy__Individual_Enrollment__r.reduivy__Target_Unit_Id__c);
                    contactIds.add(ipsUnit.reduivy__Individual_Program_Enrollment__r.reduivy__Contact__c);
                    ipfIds.add(academicProfileId);
                }
            }

            Set<String> ienFields = new Set<String>{'Id', 'Name', 'reduivy__Enrollment_Status__c'};
            SObjectType rootSObjectType = reduivy__Individual_Enrollment__c.sObjectType;

            //Generate column metadata for datatable
            JSONGenerator tableColumnMetadata = JSON.createGenerator(true);
            REDU_Datatable_UTIL.generateTableColMetadata(tableColumnMetadata, rootSObjectType, idvEnrollmentFields, true, null, enableClickableRefField, hrefTargetType, false, enableWrapText); //ISS-002104

            //Store list of fields that have ref to parent
            JSONGenerator tableFieldRefMetadata = JSON.createGenerator(true);
            REDU_Datatable_UTIL.generateRefLinksMetadata(tableFieldRefMetadata, rootSObjectType, idvEnrollmentFields);
            
            if (String.isNotBlank(idvEnrollmentFields)) {
                ienFields.addAll(idvEnrollmentFields.split(';'));
            }

            Set<String> ienAdditionalFields = new Set<String>();
            for (String field : ienFields) {
                Schema.DescribeFieldResult fieldDescribe = REDU_Datatable_UTIL.getFieldDescribe(field, rootSObjectType);

                if(fieldDescribe.getType() == Schema.DisplayType.REFERENCE) {
                    ienAdditionalFields.add(REDU_Metadata_UTIL.getReferenceFieldForQuery(field, true));
                } else if (fieldDescribe.getType() == Schema.DisplayType.PICKLIST || fieldDescribe.getType() == Schema.DisplayType.MULTIPICKLIST) {
                    ienAdditionalFields.add(REDU_Metadata_UTIL.getPicklistFieldLabelQuery(field));
                }
            }

            ienFields.addAll(ienAdditionalFields);

            if (REDU_SObject_UTIL.hasCurrencyIsoCode(rootSObjectType)) {
                ienFields.add(REDU_SObject_UTIL.CURRENCYISOCODE_FIELD);
            }
            
            List<reduivy__Individual_Enrollment__c> idvEnrollments = new List<reduivy__Individual_Enrollment__c>();
            if(!studyUnitIds.isEmpty()){

                Map<String, Object> idvEnrollmentBindParams = new Map<String, Object>{
                    'studyUnitIds' => studyUnitIds,
                    'contactIds' => contactIds,
                    'ienStudentRecordTypeId' => IEN_Helper.getStudentRecordTypeId(),
                    'ienEnrollmentTypeProgram' => IEN_Helper.ENROLLMENT_TYPE_PROGRAM,
                    'ipfIds' => ipfIds
                };

                //Query individual enrollment with related fields to be displayed in the datatable
                String queryString = 'SELECT ' + String.join(ienFields, ',');
                queryString += ' FROM reduivy__Individual_Enrollment__c ';
                queryString += ' WHERE reduivy__Target_Unit_Id__c IN : studyUnitIds AND reduivy__Contact__c IN : contactIds AND RecordTypeId =: ienStudentRecordTypeId AND reduivy__Enrollment_Type__c =: ienEnrollmentTypeProgram AND reduivy__Individual_Academic_Profile__c IN: ipfIds ';
                queryString += ' ORDER BY reduivy__Attempt_Number__c DESC NULLS LAST, reduivy__Start_Date__c DESC NULLS LAST, CreatedDate DESC';

                for(reduivy__Individual_Enrollment__c ien : (List<reduivy__Individual_Enrollment__c>) Database.queryWithBinds(queryString, idvEnrollmentBindParams, AccessLevel.USER_MODE)){
                    if(!IEN_OPEN_STATUSES.contains(ien.reduivy__Enrollment_Status__c)) {
                        idvEnrollments.add(ien);
                    }
                }
            }

            responseJSON.put(REDU_Datatable_UTIL.RECORDS_PARAM, idvEnrollments);
            responseJSON.put(REDU_Datatable_UTIL.COLUMNS_PARAM, JSON.deserializeUntyped(tableColumnMetadata.getAsString()));
            responseJSON.put(REDU_Datatable_UTIL.REFLINKS_PARAM, JSON.deserializeUntyped(tableFieldRefMetadata.getAsString()));
            responseJSON.put(REDU_TranslationManager.DATATABLE_TRANSLATION_INFO_PARAM, REDU_TranslationManager.getTranslationInfo(IEN_Helper.getApiName(), idvEnrollments, idvEnrollmentFields.split(REDU_List_UTIL.DELIMITER), language));
            responseJSON.put(REDU_Datatable_UTIL.SITE_PATH_PREFIX_PARAM, ORG_Helper.getCommunityInfo().get(ORG_Helper.SITE_PATH_PREFIX_PARAM));
            
            REDU_Logging_UTIL.debug('responseJSON', responseJSON);

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