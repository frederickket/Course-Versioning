/**
 * @author      WDCi (VTan)
 * @date        Oct 2023
 * @group       Lightning Web Component
 * @description ISS-001753 Controller for ipeAudit lightning web component.
 * @changehistory
 * ISS-002218 04-03-2025 XW - get for community from ORG_Helper
 * ISS-002562 18-07-2025 XiRouh - Added reduivy__Individual_Academic_Profile__c and reduivy__Master_Enrollment__r.reduivy__Individual_Academic_Profile__c to the IPE fields
 */
public with sharing class REDU_IpeAudit_LCTRL {

    /**
     * @description Get the details of current PE and all related child PE
     * @param individualPEId
     * @param titleField
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getIndividualPEs(Id individualPEId, String titleField) {

        try {

            Map<String, Object> responseJSON = new Map<String, Object>();

            List<reduivy__Individual_Program_Enrollment__c> individualPEs = new List<reduivy__Individual_Program_Enrollment__c>();

            List<String> positiveIpeEnrollmentStatuses = IPE_Helper.getPositiveStatuses();

            Set<String> ipeFields = new Set<String>{
                'Id',
                'RecordTypeId',
                'Name',
                'reduivy__Enrollment_Status__c',
                'reduivy__Individual_Academic_Profile__c',
                'reduivy__Master_Enrollment__r.reduivy__Individual_Academic_Profile__c'
            };

            if (String.isBlank(titleField)) {
                titleField = 'reduivy__Study_Plan__r.Name';
            }

            ipeFields.add(titleField);

            // Find the picklist field so that we add the toLabel() to the query as well
            Schema.SObjectType ipeSObjectType = reduivy__Individual_Program_Enrollment__c.sObjectType;
            Set<String> ipeAdditionalFields = new Set<String>();
            for(String field : ipeFields){
                Schema.DescribeFieldResult fieldDescribe = REDU_Datatable_UTIL.getFieldDescribe(field, ipeSObjectType);
                if(fieldDescribe.getType() == Schema.DisplayType.PICKLIST || fieldDescribe.getType() == Schema.DisplayType.MULTIPICKLIST) {
                    ipeAdditionalFields.add(REDU_Metadata_UTIL.getPicklistFieldLabelQuery(field));
                }
            }

            ipeFields.addAll(ipeAdditionalFields);

            Map<String, Object> ipeBindParams = new Map<String, Object>{
                'individualPEId' => individualPEId,
                'status' => positiveIpeEnrollmentStatuses
            };

            String ipeQuery = 'SELECT ' + String.join(ipeFields, ', ') + ', ' +
                ' (SELECT ' + String.join(ipeFields, ',') + 
                ' FROM reduivy__Child_Individual_Program_Enrollments__r ' + 
                ' WHERE reduivy__Enrollment_Status__c IN: status ' +
                ' ORDER BY CreatedDate' +
                ') ' +
                ' FROM reduivy__Individual_Program_Enrollment__c ' +
                ' WHERE Id =: individualPEId';
            
            REDU_Logging_UTIL.debug('ipeQuery', ipeQuery);

            for (reduivy__Individual_Program_Enrollment__c ipe : (List<reduivy__Individual_Program_Enrollment__c>)Database.queryWithBinds(ipeQuery, ipeBindParams, AccessLevel.USER_MODE)) {

                individualPEs.add(ipe);

                for(reduivy__Individual_Program_Enrollment__c childIpe : ipe.reduivy__Child_Individual_Program_Enrollments__r){
                    individualPEs.add(childIpe);
                }
            }
            responseJSON.put('individualPEs', individualPEs);
            responseJSON.put(ORG_Helper.IS_COMMUNITY_PARAM, ORG_Helper.isCommunity());
            
            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(responseJSON));

        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }
}