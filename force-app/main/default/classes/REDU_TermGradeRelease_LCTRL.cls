/**
 * @author      WDCi (XiRouh)
 * @date        March 2025
 * @group       Grade Release
 * @description 
 * @changehistory
 * ISS-002311 04-03-2025 XiRouh - initial version
 * ISS-002547 11-07-2025 Lean - support job queue group
 */
public with sharing class REDU_TermGradeRelease_LCTRL  {
    /*
    * @description Finds queued Jobs matching the given criteria
    * @param jobQueueGroupFields - Semi-colon separated list of Job Queue Group fields for the table
    * @param jobQueueGroupStatuses - Semi-colon separated list of applicable Job Queue Group statuses
    * @return REDU_LightningResponse
    */
    @AuraEnabled
    public static REDU_LightningResponse getJobQueueData(String jobOperation, String recordId, String jobQueueGroupFields, String jobQueueGroupStatuses){
        try {
            if (String.isBlank(jobOperation)) {
                throw new REDU_ApplicationException(String.format(Label.Missing_Required_Parameters,
                new List<String>{'jobOperation'}));
            }
            
            if (String.isBlank(recordId)) {
                throw new REDU_ApplicationException(String.format(Label.Missing_Required_Parameters,
                new List<String>{'RecordId'}));
            }

            if (String.isBlank(jobQueueGroupFields)) {
                throw new REDU_ApplicationException(String.format(Label.Missing_Required_Parameters,
                new List<String>{'jobQueueGroupFields'}));
            }

            if (String.isBlank(jobQueueGroupStatuses)) {
                throw new REDU_ApplicationException(String.format(Label.Missing_Required_Parameters,
                new List<String>{'jobQueueGroupStatuses'}));
            }
            
            SObjectType rootSObjectType = reduivy__Job_Queue_Group__c.sObjectType;
            Set<String> jqhFields = new Set<String>{'Id'};
            if (String.isNotBlank(jobQueueGroupFields)) {
                jqhFields.addAll(jobQueueGroupFields.split(';'));
            }

            Set<String> jqhAdditionalFields = new Set<String>();

            for (String field : jqhFields) {
                Schema.DescribeFieldResult fieldDescribe = REDU_Datatable_UTIL.getFieldDescribe(field, rootSObjectType);

                if(fieldDescribe.getType() == Schema.DisplayType.REFERENCE) {
                    jqhAdditionalFields.add(REDU_Metadata_UTIL.getReferenceFieldForQuery(field, true));
                } else if(fieldDescribe.getType() == Schema.DisplayType.PICKLIST || fieldDescribe.getType() == Schema.DisplayType.MULTIPICKLIST) {
                    jqhAdditionalFields.add(REDU_Metadata_UTIL.getPicklistFieldLabelQuery(field));
                }
            }

            jqhFields.addAll(jqhAdditionalFields);
            Set<String> jobQueueGroupStatusesSet = new Set<String>(jobQueueGroupStatuses.split(';'));

            Map<String, Object> jqhBindParams = new Map<String, Object>{
                'operationContext' => JQH_helper.getJobOperationContext(jobOperation, recordId),
                'jobQueueGroupStatuses' => jobQueueGroupStatusesSet
            };

            String jqhSoql = 'SELECT ' + String.join(new List<String>(jqhFields), ', ') +
                ' FROM reduivy__Job_Queue_Group__c ' +
                ' WHERE reduivy__Status__c IN :jobQueueGroupStatuses ' +
                ' AND reduivy__Job_Operation_Context__c = :operationContext ' +
                ' ORDER BY Name DESC, CreatedDate DESC '; //Show most recent first

            List<reduivy__Job_Queue_Group__c> jqhRecords = new List<reduivy__Job_Queue_Group__c>();
            
            for(reduivy__Job_Queue_Group__c jqh : (List<reduivy__Job_Queue_Group__c>) Database.queryWithBinds(jqhSoql, jqhBindParams, AccessLevel.USER_MODE)) {
                jqhRecords.add(jqh);
            }
            
            Map<String, Object> responseJSON = new Map<String, Object>{
                'jobQueueGroupRecords' => jqhRecords
            };

            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(responseJSON));

        } catch (QueryException qex) {
            REDU_Logging_UTIL.debug(qex);

            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);
        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);

            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }
}