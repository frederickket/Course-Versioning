/**
 * @author      WDCi (XiRouh)
 * @date        March 2025
 * @group       Term Offerings Cloning
 * @description 
 * @changehistory
 * ISS-002200 10-03-2025 XiRouh - description
 * ISS-002364 22-04-2024 XiRouh - Updated initQueueJob to receive the retain record name param and pass to the generator or handler
 */
public with sharing class REDU_TermOfferingsCloningModal_LCTRL {

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
                'studyTermStartDate' => stm.reduivy__Start_Date__c.format(),
                'studyTermEndDate' => stm.reduivy__End_Date__c.format(),
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
     * @description get available academic term and campus options for combobox
     * @param termId termId
     * @param educationalInstitutionId educationalInstitutionId
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getComboboxesOptions(String termId, String educationalInstitutionId){

        try {
            if (String.isBlank(termId)) {
                throw new REDU_ApplicationException(String.format(Label.Missing_Required_Parameters,
                new List<String>{'termId'}));
            }

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

            Set<String> stmFields = new Set<String>{
                'Id',
                'Name'
            };

            Map<String, Object> stmBindParams = new Map<String, Object>{
                'eduInsId' => educationalInstitutionId,
                'AcademicTermRecordTypeId' => STM_Helper.getAcademicTermRecordTypeId(),
                'termId' => termId
            };

            String stmSoql = 'SELECT ' + String.join(stmFields, ', ') +
            ' FROM reduivy__Study_Term__c ' +
            ' WHERE RecordTypeId = :AcademicTermRecordTypeId ' + 
            ' AND reduivy__Academic_Year__r.reduivy__Educational_Institution__c = :eduInsId ' + 
            ' ORDER BY reduivy__Start_Date__c ASC NULLS LAST';

            List<reduivy__Study_Term__c> stmList = new List<reduivy__Study_Term__c>();

            for(reduivy__Study_Term__c stm : (List<reduivy__Study_Term__c>) Database.queryWithBinds(stmSoql, stmBindParams, AccessLevel.USER_MODE)){
                if(stm.Id != termId) {
                    stmList.add(stm);
                }
            }

            Map<String, Object> responseData = new Map<String, Object>();
            responseData.put('campuses', campusList);
            responseData.put('academicTerms', stmList);

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
     * @description get available academic term and campus options for combobox
     * @param selectedTermId selectedTermId
     * @param selectedCampusId selectedCampusId
     * @param studyUnitFields studyUnitFields
     * @param studyOfferingStatuses studyOfferingStatuses
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getStudyUnitData(String selectedTermId, String selectedCampusId, String studyUnitFields, String studyOfferingStatuses){
        try {
            if (String.isBlank(selectedTermId)) {
                throw new REDU_ApplicationException(String.format(Label.Missing_Required_Parameters,
                new List<String>{'selectedTermId'}));
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
                'termId' => selectedTermId,
                'campusId' => selectedCampusId,
                'studyOfferingStatuses' => sofStatusesSet
            };

            String sofSoql = 'SELECT ' + String.join(new List<String>(sofFields), ', ') +
                ' FROM reduivy__Study_Offering__c ' +
                ' WHERE reduivy__Academic_Term__c = :termId ' + 
                ' AND reduivy__Campus__c = :campusId ' +
                ' AND reduivy__Status__c IN :studyOfferingStatuses ';

            Set<Id> sunIds = new Set<Id>();

            for(reduivy__Study_Offering__c sof : (List<reduivy__Study_Offering__c>) Database.queryWithBinds(sofSoql, sofBindParams, AccessLevel.USER_MODE)) {
                if(String.isNotBlank(sof.reduivy__Study_Unit__c)) {
                    sunIds.add(sof.reduivy__Study_Unit__c);
                }  
            }

            SObjectType rootSObjectType = reduivy__Study_Unit__c.sObjectType;

            Set<String> sunFields = new Set<String>{'Id'};

            sunFields.addAll(studyUnitFields.split(';'));

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

            List<reduivy__Study_Unit__c> studyUnitRecords = new List<reduivy__Study_Unit__c>();

            if(!sunIds.isEmpty()) {
                Map<String, Object> sunBindParams = new Map<String, Object>{
                    'Ids' => sunIds
                };
    
                String sunSoql = 'SELECT ' + String.join(new List<String>(sunFields), ', ') +
                    ' FROM reduivy__Study_Unit__c ' +
                    ' WHERE Id IN :Ids ' +
                    ' ORDER BY reduivy__Unit_Code__c ASC NULLS LAST, Name ASC ';

                for(reduivy__Study_Unit__c sun : (List<reduivy__Study_Unit__c>) Database.queryWithBinds(sunSoql, sunBindParams, AccessLevel.USER_MODE)) {
                    studyUnitRecords.add(sun);
                }
            }

            responseJSON.put('studyUnitRecords', studyUnitRecords);

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
     * @description get available academic term and campus options for combobox
     * @param selectedTermId selected term id from the wizard
     * @param selectedCampusId selected campus id from the wizard
     * @param selectedStudyUnitIds selected study unit ids from the wizard
     * @param studyOfferingFields studyOfferingFields to be queried
     * @param studyOfferingStatuses studyOfferingStatuses to be queried
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getStudyOfferingData(String selectedTermId, String selectedCampusId, List<Id> selectedStudyUnitIds, Integer studyOfferingTableMaximumRowNumber, String studyOfferingFields, String studyOfferingStatuses){
        try {
            if (String.isBlank(selectedTermId)) {
                throw new REDU_ApplicationException(String.format(Label.Missing_Required_Parameters,
                new List<String>{'selectedTermId'}));
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
            List<reduivy__Study_Offering__c> studyOfferingRecordsWithLimitSet = new List<reduivy__Study_Offering__c>();
            Integer totalRecordCount = 0;

            if(!selectedStudyUnitIds.isEmpty()) {
                SObjectType rootSObjectType = reduivy__Study_Offering__c.sObjectType;

                Set<String> sofFields = new Set<String>{'Id'};
                sofFields.addAll(studyOfferingFields.split(';'));

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
                    'recordIds' => selectedStudyUnitIds,
                    'studyOfferingStatuses' => sofStatusesSet,
                    'termId' => selectedTermId,
                    'campusId' => selectedCampusId,
                    'studyOfferingTableMaximumRowNumber' => studyOfferingTableMaximumRowNumber ?? 500
                };

                String sofSoql = 'SELECT ' + String.join(new List<String>(sofFields), ', ') +
                    ' FROM reduivy__Study_Offering__c ' +
                    ' WHERE reduivy__Status__c IN :studyOfferingStatuses ' +
                    ' AND reduivy__Study_Unit__c IN :recordIds ' +
                    ' AND reduivy__Academic_Term__c = :termId ' +
                    ' AND reduivy__Campus__c = :campusId ' +
                    ' ORDER BY reduivy__Code__c ASC NULLS LAST, Name ASC ' + 
                    ' LIMIT :studyOfferingTableMaximumRowNumber '; 

                for(reduivy__Study_Offering__c sof : (List<reduivy__Study_Offering__c>) Database.queryWithBinds(sofSoql, sofBindParams, AccessLevel.USER_MODE)) {
                    studyOfferingRecordsWithLimitSet.add(sof);
                }

                if(!studyOfferingRecordsWithLimitSet.isEmpty()) {
                    String countSoql = 'SELECT COUNT() ' +
                    ' FROM reduivy__Study_Offering__c ' +
                    ' WHERE reduivy__Status__c IN :studyOfferingStatuses ' +
                    ' AND reduivy__Study_Unit__c IN :recordIds ' +
                    ' AND reduivy__Academic_Term__c = :termId ' +
                    ' AND reduivy__Campus__c = :campusId ';

                    totalRecordCount = Database.countQueryWithBinds(countSoql, sofBindParams, AccessLevel.USER_MODE);
                }   
            }

            responseJSON.put('totalRecordCount', totalRecordCount);
            responseJSON.put('studyOfferingRecordsWithLimitSet', studyOfferingRecordsWithLimitSet);

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
     * @param jobOperation job operation that the term offering cloning should refer to
     * @param studyOfferingIdsToBeProcessed selected study offering ids to be processed
     * @param studyUnitIdsToBeProcessed selected study unit ids to be processed
     * @param currentTermId current term id (new study offering academic term id)
     * @param selectedTermId selected term id (academic term to be cloned from)
     * @param selectedCampusId campus to be cloned from
     * @param sofSelectionType selected selection type
     * @param studyOfferingStatuses study offering statuses to be queried
     * @return REDU_LightningResponse
     */
    @AuraEnabled
    public static REDU_LightningResponse initQueueJob(
        String jobOperation, List<Id> idsToBeProcessed,
        String currentTermId, String selectedTermId, String selectedCampusId, String sofSelectionType, String studyOfferingStatuses,
        String cloneStudySessionOption, String selectedRetainStudyOfferingNameOption, String selectedRetainStudySessionNameOption) {
        
        try {
            if (String.isBlank(jobOperation)) {
                throw new REDU_ApplicationException(String.format(Label.Missing_Required_Parameters,
                new List<String>{'jobOperation'}));
            }

            if (String.isBlank(currentTermId)) {
                throw new REDU_ApplicationException(String.format(Label.Missing_Required_Parameters,
                new List<String>{'currentTermId'}));
            }
            
            if (String.isBlank(selectedTermId)) {
                throw new REDU_ApplicationException(String.format(Label.Missing_Required_Parameters,
                new List<String>{'selectedTermId'}));
            }

            if (String.isBlank(selectedCampusId)) {
                throw new REDU_ApplicationException(String.format(Label.Missing_Required_Parameters,
                new List<String>{'selectedCampusId'}));
            }

            if (String.isBlank(sofSelectionType)) {
                throw new REDU_ApplicationException(String.format(Label.Missing_Required_Parameters,
                new List<String>{'sofSelectionType'}));
            }

            if (String.isBlank(studyOfferingStatuses)) {
                throw new REDU_ApplicationException(String.format(Label.Missing_Required_Parameters,
                new List<String>{'studyOfferingStatuses'}));
            }

            List<reduivy__Study_Term__c> studyTerms = [SELECT Id, 
                Name, reduivy__Alternate_Name__c
                FROM reduivy__Study_Term__c 
                WHERE Id =: currentTermId 
                OR Id =: selectedTermId
                WITH USER_MODE
                LIMIT 2
            ];

            String ALL_SELECTION_TYPE = Label.All;
            String MANUAL_SELECTION_TYPE = Label.Term_Offerings_Cloning_Manual_Selection;

            //Replace the map key with the map value
            Map<String, String> textsToBeReplaced = new Map<String, String>();
            reduivy__Study_Term__c currentTerm;
            reduivy__Study_Term__c selectedTerm;
            
            for(reduivy__Study_Term__c stm : studyTerms) {
                if(stm.Id == currentTermId) {
                    currentTerm = stm;
                } else {
                    selectedTerm = stm;
                }
            }
            
            if(currentTerm != null && selectedTerm != null) {
                textsToBeReplaced.put(selectedTerm.Name, currentTerm.Name);
                
                if(!String.isBlank(selectedTerm.reduivy__Alternate_Name__c) && !String.isBlank(currentTerm.reduivy__Alternate_Name__c)) {
                    textsToBeReplaced.put(selectedTerm.reduivy__Alternate_Name__c, currentTerm.reduivy__Alternate_Name__c);
                }
            }

            Map<String, Object> params = new Map<String, Object>();

            params.put('currentTermId', currentTermId);
            params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, JQH_Helper.getJobOperationContext(jobOperation, currentTermId));
            params.put('cloneStudySessionOption', String.isNotBlank(cloneStudySessionOption) ? cloneStudySessionOption : 'false');
            params.put('selectedRetainStudyOfferingNameOption', String.isNotBlank(selectedRetainStudyOfferingNameOption) ? selectedRetainStudyOfferingNameOption : 'false');
            params.put('selectedRetainStudySessionNameOption', String.isNotBlank(selectedRetainStudySessionNameOption) ? selectedRetainStudySessionNameOption : 'false');

            params.put('textsToBeReplaced', JSON.serialize(textsToBeReplaced));

            if(!idsToBeProcessed.isEmpty()) {
                if(sofSelectionType == ALL_SELECTION_TYPE) {
                    //We will have to pass it to the generator first if user choose to use all selection types
                    params.put('studyOfferingStatuses', studyOfferingStatuses);
                    params.put('selectedTermId', selectedTermId);
                    params.put('selectedCampusId', selectedCampusId);

                    JQH_JobManager.executeJobGenerator(jobOperation, idsToBeProcessed, params, true);

                } else if (sofSelectionType == MANUAL_SELECTION_TYPE) {
                    //We will directly to pass it to the handler if user choose to use manual selection types
                    params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_ID, currentTermId);
                    params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_NAME, currentTerm.Name);

                    JQH_JobQueue_OBJ job = JQH_JobManager.initNewJob(jobOperation, idsToBeProcessed, params);
                    JQH_JobManager.queueJob(job, true);
                }
            }
            
            Map<String, Object> responseJSON = new Map<String, Object>();
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