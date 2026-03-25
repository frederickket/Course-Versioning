/**
 * @author      WDCi (Lean)
 * @date        Dec 2024
 * @group       Job Queue Framework
 * @description The job queue helper
 * @changehistory
 * ISS-002219 12-12-2024 Lean - new class
 * ISS-002547 09-07-2025 Lean - enhanced to support job queue group
 */
global inherited sharing class JQH_Helper implements SObject_Helper {
    
    /**
     * @description Status - Draft
     */
    global static final String STATUS_DRAFT = 'Draft';

    /**
     * @description Status - Pending
     */
    global static final String STATUS_PENDING = 'Pending';

    /**
     * @description Status - Processing
     */
    global static final String STATUS_PROCESSING = 'Processing';

    /**
     * @description Status - Completed
     */
    global static final String STATUS_COMPLETED = 'Completed';

    /**
     * @description Status - Failed
     */
    global static final String STATUS_FAILED = 'Failed';

    /**
     * @description Status - Cancelled
     */
    global static final String STATUS_CANCELLED = 'Cancelled';

    /**
     * @description Retry Type - All Records
     */
    global static final String RETRY_TYPE_ALL = 'All Records';

    /**
     * @description Retry Type - Error Records Only
     */
    global static final String RETRY_TYPE_ERROR_ONLY = 'Error Records Only';

    /**
     * @description Return object label
     * @return String
     */
    global static String getObjectLabel() {
        return SObjectType.reduivy__Job_Queue__c.getLabel();
    }

    /**
     * @description Return object plural label
     * @return String
     */
    global static String getObjectPluralLabel() {
        return SObjectType.reduivy__Job_Queue__c.getLabelPlural();
    }

    /**
     * @description Return object api name
     * @return String
     */
    global static String getApiName() {
        return SObjectType.reduivy__Job_Queue__c.getName();
    }

    /**
     * @description Return the translation field name for name
     */
    global static String getTranslationFieldNameForName() {
        String formulaFieldName = REDU_TranslationManager.getSObjectTranslationFieldNameForName(SObjectType.reduivy__Job_Queue__c);

        return String.isBlank(formulaFieldName) ? 'Name' : formulaFieldName;
    }

    /**
     * @description Get pending jobs for a user
     * @param userId
     * @return List<reduivy__Job_Queue__c>
     */
    public static List<reduivy__Job_Queue__c> getPendingJobsForUser(Id userId) {
        
        try {
            Set<String> jqhFields = new Set<String>{
                'Id',
                'Name',
                'reduivy__End_Datetime__c',
                'reduivy__Job_Handler_Class_Name__c',
                'reduivy__Job_Handler_Error_Record_Ids__c',
                'reduivy__Job_Handler_Params__c',
                'reduivy__Job_Handler_Record_Ids__c',
                'reduivy__Job_Handler_Warning_Record_Ids__c',
                'reduivy__Job_Handler_Success_Record_Ids__c',
                'reduivy__Job_Operation__c',
                'reduivy__Job_Operation_Context__c',
                'reduivy__Number_of_Attempts__c',
                'reduivy__Number_of_Error_Records__c',
                'reduivy__Number_of_Records__c',
                'reduivy__Number_of_Warning_Records__c',
                'reduivy__Origin_Job_Queue_ID__c',
                'reduivy__Source_Record_Id__c',
                'reduivy__Source_Record_Name__c',
                'reduivy__Start_Datetime__c',
                'reduivy__Status__c',
                'OwnerId',
                'reduivy__Job_Queue_Group__c'
            };

            Map<String, Object> jqhBindParams = new Map<String, Object>();
            jqhBindParams.put('jobQueueStatus', STATUS_PENDING);
            jqhBindParams.put('jobQueueGroupStatus', new Set<String>{JQG_Helper.STATUS_PENDING, JQG_Helper.STATUS_PROCESSING});
            jqhBindParams.put('ownerId', userId);

            String jqhSoql = 'SELECT ' + String.join(jqhFields, ', ') + 
                ' FROM reduivy__Job_Queue__c ' + 
                ' WHERE reduivy__Status__c =: jobQueueStatus ' + 
                ' AND OwnerId =: ownerId ' +
                ' AND reduivy__Job_Queue_Group__r.reduivy__Status__c IN: jobQueueGroupStatus ' +
                ' ORDER BY reduivy__Job_Queue_Group__r.CreatedDate ASC, Name ASC, CreatedDate ASC';

            List<reduivy__Job_Queue__c> queueList = new List<reduivy__Job_Queue__c>();

            for (reduivy__Job_Queue__c jobQueue : (List<reduivy__Job_Queue__c>) Database.queryWithBinds(jqhSoql, jqhBindParams, AccessLevel.USER_MODE)) {
                queueList.add(jobQueue);
            }

            return queueList;

        } catch (QueryException qex) {
            REDU_ObjectSecurity_UTIL.handleQueryException(qex, false);
            return null;
        }
    }

    /**
     * @description Get the next job available in the queue for the current user
     * @return reduivy__Job_Queue__c
     */
    public static reduivy__Job_Queue__c getNextJob() {
        List<reduivy__Job_Queue__c> jobQueues = getPendingJobsForUser(UserInfo.getUserId());

        if (jobQueues.isEmpty()) {
            return null;
        }

        return jobQueues.get(0);
    }

    /**
     * @description Check for the async job list to see if the job worker batch is currently running
     * @return Boolean
     */
	public static Boolean isWorkerFree() {

        Set<String> jobTypes = new Set<String>{
            'Queueable'
        };

        Set<String> statuses = new Set<String>{
            'Processing',
            'Preparing',
            'Queued'
        };

        //we need to query the AsyncApexJob as non administrative user
		Integer runningWorker = [SELECT COUNT() 
            FROM AsyncApexJob
            WHERE JobType IN: jobTypes
            AND ApexClass.Name = 'JQH_JobWorker_QUEUE'
            AND Status IN: statuses
            AND CreatedById =: UserInfo.getUserId()
            WITH USER_MODE
        ];
		
		return (runningWorker == 0);
	}

    /**
     * @description List of job queue config metadata
     */
    private static List<reduivy__Job_Queue_Config__mdt> jobQueueConfigs;

    /**
     * @description Job queue configs metadata
     * @return List<reduivy__Job_Queue_Config__mdt>
     */
    public static List<reduivy__Job_Queue_Config__mdt> getJobQueueConfig() {

        if (jobQueueConfigs == null) {
            jobQueueConfigs = new List<reduivy__Job_Queue_Config__mdt>();
            
            List<reduivy__Job_Queue_Config__mdt> configs = reduivy__Job_Queue_Config__mdt.getAll().values();

            for (reduivy__Job_Queue_Config__mdt config : configs) {
                //we will return all active and inactive configs so that we can create the inactive config as skipped job for tracking and retry purposes
                jobQueueConfigs.add(config);
            }
        }

        return jobQueueConfigs;
    }

    /**
     * @description Job queue configs metadata grouped by job operation
     */
    private static Map<String, reduivy__Job_Queue_Config__mdt> jobQueueConfigsMap;

    /**
     * @description Return a map of job queue configs metadata grouped by job operation name
     * @return Map<String, reduivy__Job_Queue_Config__mdt>
     */
    public static Map<String, reduivy__Job_Queue_Config__mdt> getJobConfigsByOperation() {
        if (jobQueueConfigsMap == null) {
            jobQueueConfigsMap = new Map<String, reduivy__Job_Queue_Config__mdt>();

            for (reduivy__Job_Queue_Config__mdt config : getJobQueueConfig()) {
                if (String.isNotBlank(config.reduivy__Job_Operation__c) && String.isNotBlank(config.reduivy__Job_Handler_Class_Name__c))
                jobQueueConfigsMap.put(config.reduivy__Job_Operation__c, config);
            }
        }

        return jobQueueConfigsMap;
    }

    /**
     * @description Return a job config based on the job operation
     * @return reduivy__Job_Queue_Config__mdt
     */
    public static reduivy__Job_Queue_Config__mdt getJobOperationSettings(String jobOperation) {
        
        if (String.isNotBlank(jobOperation) && getJobConfigsByOperation().containsKey(jobOperation)) {
            return getJobConfigsByOperation().get(jobOperation);

        } else {
            String message = String.format(Label.Missing_Job_Queue_Config, new List<String>{jobOperation});

            throw new REDU_ApplicationException(message);
        }
    }

    /**
     * @description Convert the reduivy__Job_Queue__c object to JQH_JobQueue_OBJ
     * @param jobQueue
     * @return JQH_JobQueue_OBJ
     */
    public static JQH_JobQueue_OBJ toJobObject(reduivy__Job_Queue__c jobQueue) {

        JQH_JobQueue_OBJ job = new JQH_JobQueue_OBJ(jobQueue);

        return job;
    }

    /**
     * @description Convert list of id to semi-colon separated value string
     * @param recordIds
     * @return String
     */
    public static String serializeRecordIds(List<Id> recordIds) {
        String recordIdsString = '';

        if (recordIds != null && !recordIds.isEmpty()) {
            recordIdsString = String.join(recordIds, REDU_List_UTIL.DELIMITER);
        }

        return recordIdsString;
    }

    /**
     * @description Convert list of id to semi-colon separated value string
     * @param recordIds
     * @return String
     */
    public static String serializeRecordIds(Set<Id> recordIds) {
        String recordIdsString = '';

        if (recordIds != null && !recordIds.isEmpty()) {
            recordIdsString = String.join(new List<Id>(recordIds), REDU_List_UTIL.DELIMITER);
        }

        return recordIdsString;
    }

    /**
     * @description Convert string of ids to list of id
     * @param recordIdsString
     * @return List<Id>
     */
    public static List<Id> deserializeRecordIds(String recordIdsString) {

        List<Id> recordIds = new List<Id>();

        if (String.isNotBlank(recordIdsString)) {
            List<String> stringList = recordIdsString.split(REDU_List_UTIL.DELIMITER);

            try {
                recordIds = (List<Id>) stringList;
            } catch (Exception exp) {
                String message = String.format(Label.Error_Converting_String_To_Id, new List<String>{recordIdsString});
                throw new REDU_ApplicationException(message);
            }
        }

        return recordIds;
    }

    /**
     * @description Convert key pair value map to json string
     * @param params
     * @return String
     */
    public static String serializeParams(Map<String, Object> params) {
        Map<String, Object> localParams = new Map<String, Object>();
        if (params != null) {
            localParams = params;
        }

        return JSON.serialize(localParams);
    }

    /**
     * @description Convert string of params to key pair value map
     * @param paramsString
     * @return Map<String, Object>
     */
    public static Map<String, Object> deserializeParams(String paramsString) {
        Map<String, Object> params = new Map<String, Object>();

        if (String.isNotBlank(paramsString)) {
            try {
                params = (Map<String, Object>) JSON.deserializeUntyped(paramsString);
            } catch (Exception exp) {
                String message = String.format(Label.Error_Deserializing_Params, new List<String>{paramsString});
                throw new REDU_ApplicationException(message);
            }
        }

        return params;
    }

    /**
     * @description Init job handler based on class name
     * @param jobHandlerClassName
     * @return JQH_JobHandler
     */
    public static JQH_JobHandler getHandlerClass(String jobHandlerClassName) {
        JQH_JobHandler jobHandler;
        
        // Throw exception if class name empty
        if(String.isBlank(jobHandlerClassName)) {
        	String message = Label.Missing_Job_Handler_Class_Name;
           	throw new REDU_ApplicationException(message);
        }

        Type classType = Type.forName(jobHandlerClassName);
        if (classType != null) {
            jobHandler = (JQH_JobHandler) classType.newInstance();
        }
        
        if (jobHandler == null) {
            String message = String.format(Label.Error_Initializing_Job_Handler, new List<String>{jobHandlerClassName});
            throw new REDU_ApplicationException(message);
        }

        return jobHandler;
    }

    /**
     * @description Init job generator based on class name
     * @param jobGeneratorClassName
     * @return JQH_JobGenerator
     */
    public static JQH_JobGenerator getGeneratorClass(String jobGeneratorClassName) {
        
        JQH_JobGenerator jobGenerator;

        // Throw exception if class name empty
        if(String.isBlank(jobGeneratorClassName)) {
        	String message = Label.Missing_Job_Generator_Class_Name;
           	throw new REDU_ApplicationException(message);
        }
        
        Type classType = Type.forName(jobGeneratorClassName);

        if (classType != null) {
            jobGenerator = (JQH_JobGenerator) classType.newInstance();
        }

        if (jobGenerator == null) {
            String message = String.format(Label.Error_Initializing_Job_Generator, new List<String>{jobGeneratorClassName});
            throw new REDU_ApplicationException(message);
        }

        return jobGenerator;
    }

    /**
     * @description Split the job to multiple jobs based on the batch size
     * @param job
     * @return List<reduivy__Job_Queue__c>
     */
    public static List<reduivy__Job_Queue__c> getBatchedJobQueues(JQH_JobQueue_OBJ job) {

        List<reduivy__Job_Queue__c> batchedJobs = new List<reduivy__Job_Queue__c>();

        List<List<Id>> pagedIds = REDU_List_UTIL.getPageIterable(job.getRecordIds(), job.getBatchSize());

        if (!pagedIds.isEmpty()) {
            for (List<Id> ids : pagedIds) {
                reduivy__Job_Queue__c jqh = job.getSObject().clone(false, true, false, false);
                jqh.reduivy__Job_Handler_Record_Ids__c = JQH_Helper.serializeRecordIds(ids);

                batchedJobs.add(jqh);
            }
        } else {
            //if the record ids is empty, we just add the original job into the list
            batchedJobs.add(job.getSObject());
        }

        return batchedJobs;
    }

    /**
     * @description Set the job queue status to processing
     * @return void
     */
    public static void jobStarted(reduivy__Job_Queue__c jobQueue) {

        if (jobQueue != null && String.isNotBlank(jobQueue.Id)) {

            jobQueue.reduivy__Status__c = JQH_Helper.STATUS_PROCESSING;
            jobQueue.reduivy__Start_Datetime__c = System.now();

            reduivy__Job_Queue__c jqhUpdate = new reduivy__Job_Queue__c(
                Id = jobQueue.Id,
                reduivy__Status__c = jobQueue.reduivy__Status__c,
                reduivy__Start_Datetime__c = jobQueue.reduivy__Start_Datetime__c
            );

            REDU_SystemMode_UTIL.doUpdate(new List<reduivy__Job_Queue__c>{jqhUpdate});
        }
    }

    /**
     * @description Set the job queue completion status and log related errors if there is any
     * @param results The job handler results
     * @return void
     */
    public static void jobCompleted(reduivy__Job_Queue__c jobQueue, JQH_JobManager.HandlerResult results) {

        if (jobQueue != null && String.isNotBlank(jobQueue.Id)) {
            Boolean hasFailure = false;

            jobQueue.reduivy__Status__c = JQH_Helper.STATUS_COMPLETED;
            jobQueue.reduivy__End_Datetime__c = System.now();

            //set the success ids if has success records
            if (results.success != null && !results.success.isEmpty()) {
                jobQueue.reduivy__Job_Handler_Success_Record_Ids__c = JQH_Helper.serializeRecordIds(results.success.keySet());
            }

            //set the warning ids if has warning records
            if (results.warning != null && !results.warning.isEmpty()) {
                jobQueue.reduivy__Job_Handler_Warning_Record_Ids__c = JQH_Helper.serializeRecordIds(results.warning.keySet());
            }

            //set the error status and error ids if has failure records
            if (results.fail != null && !results.fail.isEmpty()) {
                jobQueue.reduivy__Job_Handler_Error_Record_Ids__c = JQH_Helper.serializeRecordIds(results.fail.keySet());
                jobQueue.reduivy__Status__c = JQH_Helper.STATUS_FAILED;

                hasFailure = true;
            }

            reduivy__Job_Queue__c jqhUpdate = new reduivy__Job_Queue__c(
                Id = jobQueue.Id,
                reduivy__Status__c = jobQueue.reduivy__Status__c,
                reduivy__Start_Datetime__c = jobQueue.reduivy__Start_Datetime__c,
                reduivy__End_Datetime__c = jobQueue.reduivy__End_Datetime__c,
                reduivy__Job_Handler_Success_Record_Ids__c = jobQueue.reduivy__Job_Handler_Success_Record_Ids__c,
                reduivy__Job_Handler_Error_Record_Ids__c = jobQueue.reduivy__Job_Handler_Error_Record_Ids__c,
                reduivy__Job_Handler_Warning_Record_Ids__c = jobQueue.reduivy__Job_Handler_Warning_Record_Ids__c

            );

            REDU_SystemMode_UTIL.doUpdate(new List<reduivy__Job_Queue__c>{jqhUpdate});
        }
    }

    /**
     * @description Set the job queue status to failed
     * @return void
     */
    public static void jobFailed(reduivy__Job_Queue__c jobQueue) {

        if (jobQueue != null && String.isNotBlank(jobQueue.Id)) {

            jobQueue.reduivy__Status__c = JQH_Helper.STATUS_FAILED;
            jobQueue.reduivy__End_Datetime__c = System.now();

            reduivy__Job_Queue__c jqhUpdate = new reduivy__Job_Queue__c(
                Id = jobQueue.Id,
                reduivy__Status__c = jobQueue.reduivy__Status__c,
                reduivy__End_Datetime__c = jobQueue.reduivy__End_Datetime__c
            );

            REDU_SystemMode_UTIL.doUpdate(new List<reduivy__Job_Queue__c>{jqhUpdate});
        }
    }

    /**
     * @description Get job operation context
     * @param jobOperation
     * @param recordId
     * @return String
     */
    public static String getJobOperationContext(String jobOperation, String recordId) {
        return jobOperation + '_' + recordId;
    }

    /**
     * @description ISS-002547 Link log to job queue and job queue group
     * @param log
     * @param jobQueue
     * @return void
     */
    public static void linkLogToJobs(reduivy__Log__c log, reduivy__Job_Queue__c jobQueue) {

        log.reduivy__Job_Queue__c = jobQueue?.Id;
        log.reduivy__Job_Queue_Group__c = jobQueue?.reduivy__Job_Queue_Group__c;
    }
}