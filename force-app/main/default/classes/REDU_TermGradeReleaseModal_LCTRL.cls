/**
 * @author      WDCi (XiRouh)
 * @date        March 2025
 * @group       Grade Release
 * @description 
 * @changehistory
 * ISS-002311 05-03-2025 XiRouh - initial version
 */
public with sharing class REDU_TermGradeReleaseModal_LCTRL {

    /**
     * @description get study term details
     * @param studyTermRecordId studyTermRecordId
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable = true)
    public static REDU_LightningResponse getStudyTermDetails(Id studyTermRecordId) {
        try {
            if (String.isBlank(studyTermRecordId)) {
                throw new REDU_ApplicationException(String.format(Label.Missing_Required_Parameters, 
                new List<String>{'studyTermRecordId'}));
            }
    
            Set<String> stmFields = new Set<String>{
                'Name',
                'reduivy__Start_Date__c',
                'reduivy__End_Date__c',
                'reduivy__Academic_Year__r.reduivy__Educational_Institution__c'
            };

            Map<String, Object> stmBindParams = new Map<String, Object>();
            stmBindParams.put('Id', studyTermRecordId);
            stmBindParams.put('AcademicTermRecordTypeId', STM_Helper.getAcademicTermRecordTypeId());

            String stmSoql = 'SELECT ' + String.join(stmFields, ', ') +
                ' FROM reduivy__Study_Term__c ' +
                ' WHERE Id = :Id ' + 
                ' AND RecordTypeId = :AcademicTermRecordTypeId ';

            List<reduivy__Study_Term__c> stmList = Database.queryWithBinds(stmSoql, stmBindParams, AccessLevel.USER_MODE);
    
            if (stmList.isEmpty()) {
                throw new REDU_ApplicationException(String.format(Label.Invalid_Record_Id_For_Object_Type,
                    new List<String>{studyTermRecordId, STM_Helper.getAcademicTermRecordTypeLabel()}));
            }
    
            reduivy__Study_Term__c stm = stmList[0];
    
            Map<String, String> responseData = new Map<String, String>{
                'studyTermName' => stm.Name,
                'educationalInstitutionId' => stm.reduivy__Academic_Year__r.reduivy__Educational_Institution__c
            };
    
            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(responseData));
        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);
    
        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description get available campus options for combobox
     * @param educationalInstitutionId educationalInstitutionId
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getComboboxesOptions(String educationalInstitutionId){

        try {
            if (String.isBlank(educationalInstitutionId)) {
                throw new REDU_ApplicationException(String.format(Label.Missing_Required_Parameters,
                new List<String>{'educationalInstitutionId'}));
            }

            Set<String> accFields = new Set<String>{
                'Id',
                'Name'
            };

            Map<String, Object> accBindParams = new Map<String, Object>{
                'eduInsId' => educationalInstitutionId,
                'campusRecordTypeId' => ACC_Helper.getCampusRecordTypeId()
            };

            String accSoql = 'SELECT ' + String.join(accFields, ', ') +
            ' FROM Account ' +
            ' WHERE RecordTypeId = :campusRecordTypeId ' + 
            ' AND ParentId = :eduInsId ';

            List<Account> campusList = new List<Account>();

            for(Account acc : (List<Account>) Database.queryWithBinds(accSoql, accBindParams, AccessLevel.USER_MODE)){
                campusList.add(acc);
            }

            Map<String, Object> responseData = new Map<String, Object>();
            responseData.put('campuses', campusList);

            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(responseData));

        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /*
    * @description Finds study unit data that have study offerings with the given statuses and term id
    * @param termId - The record Id of the term
    * @param studyUnitFields - Semi-colon separated list of study unit fields for the table
    * @param studyOfferingStatuses - Semi-colon separated list of applicable study offering statuses
    * @return REDU_LightningResponse
    */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getStudyUnitData(String termId, String selectedCampusId, String studyUnitFields, String studyOfferingStatuses){
        try {
            if (String.isBlank(termId)) {
                throw new REDU_ApplicationException(String.format(Label.Missing_Required_Parameters,
                new List<String>{'termId'}));
            }

            if (String.isBlank(selectedCampusId)) {
                throw new REDU_ApplicationException(String.format(Label.Missing_Required_Parameters,
                new List<String>{'selectedCampusId'}));
            }

            if (String.isBlank(studyUnitFields)) {
                throw new REDU_ApplicationException(String.format(Label.Missing_Required_Parameters,
                new List<String>{'studyUnitFields'}));
            }

            if (String.isBlank(studyOfferingStatuses)) {
                throw new REDU_ApplicationException(String.format(Label.Missing_Required_Parameters,
                new List<String>{'studyOfferingStatuses'}));
            }

            Map<String, Object> responseJSON = new Map<String, Object>();

            Set<String> sofFields = new Set<String>{'Id', 'reduivy__Study_Unit__c'};
            Set<String> sofStatusesSet = new Set<String>(studyOfferingStatuses.split(';'));

            Map<String, Object> sofBindParams = new Map<String, Object>{
                'termId' => termId,
                'sofStatusesSet' => sofStatusesSet,
                'campusId' => selectedCampusId
            };

            String sofSoql = 'SELECT ' + String.join(new List<String>(sofFields), ', ') +
                ' FROM reduivy__Study_Offering__c ' +
                ' WHERE reduivy__Academic_Term__c = :termId ' +
                ' AND reduivy__Campus__c = :campusId ' +
                ' AND reduivy__Booked_Places__c > 0 ' +
                ' AND reduivy__Status__c IN :sofStatusesSet ' ;

            Set<Id> sunIds = new Set<Id>();

            for(reduivy__Study_Offering__c sof : (List<reduivy__Study_Offering__c>) Database.queryWithBinds(sofSoql, sofBindParams, AccessLevel.USER_MODE)) {
                if(String.isNotBlank(sof.reduivy__Study_Unit__c)) {
                    sunIds.add(sof.reduivy__Study_Unit__c);
                }  
            }

            SObjectType rootSObjectType = reduivy__Study_Unit__c.sObjectType;

            Set<String> sunFields = new Set<String>{'Id'};

            if (String.isNotBlank(studyUnitFields)) {
                sunFields.addAll(studyUnitFields.split(';'));
            }

            Set<String> sunAdditionalFields = new Set<String>();

            for (String field : sunFields) {
                Schema.DescribeFieldResult fieldDescribe = REDU_Datatable_UTIL.getFieldDescribe(field, rootSObjectType);

                if(fieldDescribe.getType() == Schema.DisplayType.REFERENCE) {
                    sunAdditionalFields.add(REDU_Metadata_UTIL.getReferenceFieldForQuery(field, true));
                } else if(fieldDescribe.getType() == Schema.DisplayType.PICKLIST || fieldDescribe.getType() == Schema.DisplayType.MULTIPICKLIST) {
                    sunAdditionalFields.add(REDU_Metadata_UTIL.getPicklistFieldLabelQuery(field));
                }
            }

            sunFields.addAll(sunAdditionalFields);

            if(!sunIds.isEmpty()) {
                Map<String, Object> sunBindParams = new Map<String, Object>{
                    'Ids' => sunIds
                };
    
                String sunSoql = 'SELECT ' + String.join(new List<String>(sunFields), ', ') +
                    ' FROM reduivy__Study_Unit__c ' +
                    ' WHERE Id IN :Ids ' +
                    ' ORDER BY reduivy__Unit_Code__c ASC NULLS LAST, Name ASC ';
    
                List<reduivy__Study_Unit__c> studyUnitRecords = new List<reduivy__Study_Unit__c>();

                for(reduivy__Study_Unit__c sun : (List<reduivy__Study_Unit__c>) Database.queryWithBinds(sunSoql, sunBindParams, AccessLevel.USER_MODE)) {
                    studyUnitRecords.add(sun);
                }
                
                responseJSON.put('studyUnitRecords', studyUnitRecords);
            }

            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(responseJSON));

        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);
        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /*
    * @description Finds study offering matching the given criteria
    * @param studyUnitIds - The study unit record ids
    * @param studyOfferingFields - Semi-colon separated list of study offering fields for the table
    * @param studyOfferingStatuses - Semi-colon separated list of applicable study offering statuses
    * @return REDU_LightningResponse
    */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getStudyOfferingData(String termId, String selectedCampusId, List<Id> studyUnitIds, String studyOfferingFields, String studyOfferingStatuses){
        try {
            if (String.isBlank(termId)) {
                throw new REDU_ApplicationException(String.format(Label.Missing_Required_Parameters,
                new List<String>{'termId'}));
            }

            if (String.isBlank(selectedCampusId)) {
                throw new REDU_ApplicationException(String.format(Label.Missing_Required_Parameters,
                new List<String>{'selectedCampusId'}));
            }

            if (String.isBlank(studyOfferingFields)) {
                throw new REDU_ApplicationException(String.format(Label.Missing_Required_Parameters,
                new List<String>{'studyOfferingFields'}));
            }

            if (String.isBlank(studyOfferingStatuses)) {
                throw new REDU_ApplicationException(String.format(Label.Missing_Required_Parameters,
                new List<String>{'studyOfferingStatuses'}));
            }

            Map<String, Object> responseJSON = new Map<String, Object>();
            
            if(!studyUnitIds.isEmpty()) {
                SObjectType rootSObjectType = reduivy__Study_Offering__c.sObjectType;

                Set<String> sofFields = new Set<String>{'Id'};
                if (String.isNotBlank(studyOfferingFields)) {
                    sofFields.addAll(studyOfferingFields.split(';'));
                }

                Set<String> sofAdditionalFields = new Set<String>();
                for (String field : sofFields) {
                    Schema.DescribeFieldResult fieldDescribe = REDU_Datatable_UTIL.getFieldDescribe(field, rootSObjectType);

                    if(fieldDescribe.getType() == Schema.DisplayType.REFERENCE) {
                        sofAdditionalFields.add(REDU_Metadata_UTIL.getReferenceFieldForQuery(field, true));
                    } else if(fieldDescribe.getType() == Schema.DisplayType.PICKLIST || fieldDescribe.getType() == Schema.DisplayType.MULTIPICKLIST) {
                        sofAdditionalFields.add(REDU_Metadata_UTIL.getPicklistFieldLabelQuery(field));
                    }
                }

                sofFields.addAll(sofAdditionalFields);

                Set<String> sofStatusesSet = new Set<String>(studyOfferingStatuses.split(';'));

                Map<String, Object> sofBindParams = new Map<String, Object>{
                    'recordIds' => studyUnitIds,
                    'studyOfferingStatuses' => sofStatusesSet,
                    'termId' => termId,
                    'campusId' => selectedCampusId
                };

                String sofSoql = 'SELECT ' + String.join(new List<String>(sofFields), ', ') +
                    ' FROM reduivy__Study_Offering__c ' +
                    ' WHERE reduivy__Status__c IN :studyOfferingStatuses ' +
                    ' AND reduivy__Study_Unit__c IN :recordIds ' +
                    ' AND reduivy__Academic_Term__c = :termId ' +
                    ' AND reduivy__Campus__c = :campusId ' +
                    ' AND reduivy__Booked_Places__c > 0 ' +
                    ' ORDER BY reduivy__Code__c ASC NULLS LAST, Name ASC'; 

                List<reduivy__Study_Offering__c> studyOfferingRecords = new List<reduivy__Study_Offering__c>();

                for(reduivy__Study_Offering__c sof : (List<reduivy__Study_Offering__c>) Database.queryWithBinds(sofSoql, sofBindParams, AccessLevel.USER_MODE)) {
                    studyOfferingRecords.add(sof);
                }

                responseJSON.put('studyOfferingRecords', studyOfferingRecords);
            }
            
            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(responseJSON));

        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);
        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description To init queue job
     * @param termId
     * @param jobOperation
     * @param toBeProcessedStudyOfferingIds
     * @param selectedGradeReleaseStatus
     * @return REDU_LightningResponse
     */
    @AuraEnabled
    public static REDU_LightningResponse initQueueJob(String termId, String jobOperation, List<Id> toBeProcessedStudyOfferingIds, String selectedGradeReleaseStatus) {
        
        try {
            if (String.isBlank(termId)) {
                throw new REDU_ApplicationException(String.format(Label.Missing_Required_Parameters,
                new List<String>{'termId'}));
            }

            if (String.isBlank(jobOperation)) {
                throw new REDU_ApplicationException(String.format(Label.Missing_Required_Parameters,
                new List<String>{'jobOperation'}));
            }

            if (String.isBlank(selectedGradeReleaseStatus)) {
                throw new REDU_ApplicationException(String.format(Label.Missing_Required_Parameters,
                new List<String>{'selectedGradeReleaseStatus'}));
            }

            if(!toBeProcessedStudyOfferingIds.isEmpty()){

                Map<String, Object> params = new Map<String, Object>();
                params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, JQH_Helper.getJobOperationContext(jobOperation, termId));
                params.put('selectedGradeReleaseStatus', selectedGradeReleaseStatus);

                JQH_JobManager.executeJobGenerator(jobOperation, toBeProcessedStudyOfferingIds, params, true);
            }

            Map<String, Object> responseJSON = new Map<String, Object>();
            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(responseJSON));

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }
}