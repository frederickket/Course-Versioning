/**
 * @author      WDCi (Lean)
 * @date        Dec 2024
 * @group       Job Queue Framework
 * @description The job handler worker
 * @changehistory
 * ISS-002219 11-12-2024 Lean - new class
 * ISS-002547 09-07-2025 Lean - enhanced to support job queue group
 */
global inherited sharing class JQH_JobQueue_OBJ {
    
    /**
     * @description System param key - jobOperationContext
     */
    global static final String PARAM_JOB_OPERATION_CONTEXT = 'jobOperationContext';

    /**
     * @description System param key - sourceRecordId
     */
    global static final String PARAM_SOURCE_RECORD_ID = 'sourceRecordId';

    /**
     * @description System param key - sourceRecordName
     */
    global static final String PARAM_SOURCE_RECORD_NAME = 'sourceRecordName';

    /**
     * @description System param key - hasCallout
     */
    public static final String PARAM_HAS_CALLOUT = 'hasCallout';

    /**
     * @description System param key - isRetry
     */
    public static final String PARAM_IS_RETRY = 'isRetry';

    /**
     * @description System param key - lastAttemptCount
     */
    public static final String PARAM_LAST_ATTEMPT_COUNT = 'lastAttemptCount';

    /**
     * @description System param key - retryOriginJobNo
     */
    public static final String PARAM_RETRY_ORIGIN_JOB_QUEUE_NO = 'retryOriginJobNo';

    /**
     * @description Job operation name
     */
    private String jobOperation;
    
    /**
     * @description List of record id
     */
    private List<Id> recordIds;

    /**
     * @description Map of params in key value pair
     */
    private Map<String, Object> params;

    /**
     * @description Job operation context
     */
    private String jobOperationContext;

    /**
     * @description Source record id
     */
    private Id sourceRecordId;

    /**
     * @description Source record name
     */
    private String sourceRecordName;

    /**
     * @description isRetry
     */
    private Boolean isRetry;

    /**
     * @description lastAttemptCount
     */
    private Decimal lastAttemptCount;

    /**
     * @description retryOriginJobNo
     */
    private String retryOriginJobNo;

    /**
     * @description Job handler
     */
    private JQH_JobHandler jobHandler;

    /**
     * @description reduivy__Job_Queue__c object
     */
    private reduivy__Job_Queue__c jobQueue;

    /**
     * @description reduivy__Job_Queue_Config__mdt object
     */
    private reduivy__Job_Queue_Config__mdt jobConfig;

    /**
     * @description List of reduivy__Log__c object
     */
    private List<reduivy__Log__c> jobLogs;

    /**
     * @description Job queue group Id
     */
    private Id jobQueueGroupId;

    /**
     * @description Contructor to init a new job
     * @param jobOperation The operation name
     * @param recordIds The record ids to be processed
     * @param params The parameters to be passed to the handler
     */
    public JQH_JobQueue_OBJ(String jobOperation, List<Id> recordIds, Map<String, Object> params) {

        this.recordIds = new List<Id>();
        this.params = new Map<String, Object>();
        this.jobLogs = new List<reduivy__Log__c>();

        this.jobOperation = jobOperation;

        if (recordIds != null) {
            this.recordIds = recordIds;
        }

        if (params != null) {
            this.params = params;
        }
    }

    /**
     * @description Constructor to init a job object using existing job queue record
     * @param jobQueue The job queue record
     */
    public JQH_JobQueue_OBJ(reduivy__Job_Queue__c jobQueue) {

        this.jobLogs = new List<reduivy__Log__c>();

        this.jobOperation = jobQueue.reduivy__Job_Operation__c;
        this.recordIds = JQH_Helper.deserializeRecordIds(jobQueue.reduivy__Job_Handler_Record_Ids__c);
        this.params = JQH_Helper.deserializeParams(jobQueue.reduivy__Job_Handler_Params__c);
        
        this.jobQueue = jobQueue;
    }

    /**
     * @description Return job operation context
     * @return String
     */
    public String getJobOperationContext() {
        if (String.isBlank(this.jobOperationContext) && getJobParams().containsKey(PARAM_JOB_OPERATION_CONTEXT)) {
            this.jobOperationContext = String.valueOf(String.valueOf(getJobParams().get(PARAM_JOB_OPERATION_CONTEXT)));
        }

        return this.jobOperationContext;
    }

    /**
     * @description Return source record id
     * @return Id
     */
    public Id getSourceRecordId() {
        if (String.isBlank(this.sourceRecordId) && getJobParams().containsKey(PARAM_SOURCE_RECORD_ID)) {
            this.sourceRecordId = Id.valueOf(String.valueOf(getJobParams().get(PARAM_SOURCE_RECORD_ID)));
        }

        return this.sourceRecordId;
    }

    /**
     * @description Return source record name
     * @return String
     */
    public String getSourceRecordName() {
        if (String.isBlank(this.sourceRecordName) && getJobParams().containsKey(PARAM_SOURCE_RECORD_NAME)) {
            this.sourceRecordName = String.valueOf(getJobParams().get(PARAM_SOURCE_RECORD_NAME));
        }

        return this.sourceRecordName;
    }

    /**
     * @description Return is retry flag
     * @return Boolean
     */
    public Boolean isRetry() {
        
        if (this.isRetry == null && getJobParams().containsKey(PARAM_IS_RETRY)) {
            this.isRetry = Boolean.valueOf(getJobParams().get(PARAM_IS_RETRY));
        }

        if (this.isRetry == null) {
            this.isRetry = false;
        }

        return this.isRetry;
    }

    /**
     * @description Return last attempt count
     * @return Decimal
     */
    public Decimal getLastAttemptCount() {
        if (this.lastAttemptCount == null && getJobParams().containsKey(PARAM_LAST_ATTEMPT_COUNT)) {
            this.lastAttemptCount = (Decimal) getJobParams().get(PARAM_LAST_ATTEMPT_COUNT);
        }

        if (this.lastAttemptCount == null) {
            this.lastAttemptCount = 0;
        }

        return this.lastAttemptCount;
    }

    /**
     * @description Return retry origin job number
     * @return String
     */
    public String getRetryOriginJobNo() {
        if (String.isBlank(this.retryOriginJobNo) && getJobParams().containsKey(PARAM_RETRY_ORIGIN_JOB_QUEUE_NO)) {
            this.retryOriginJobNo = String.valueOf(getJobParams().get(PARAM_RETRY_ORIGIN_JOB_QUEUE_NO));
        }

        return this.retryOriginJobNo;
    }

    /**
     * @description Return the job queue record
     * @return reduivy__Job_Queue__c
     */
    public reduivy__Job_Queue__c getSObject() {

        if (this.jobQueue == null && getJobConfig() != null) {

            this.jobQueue = new reduivy__Job_Queue__c();
            this.jobQueue.reduivy__Job_Operation__c = this.jobOperation;
            this.jobQueue.reduivy__Job_Handler_Class_Name__c = getJobConfig().reduivy__Job_Handler_Class_Name__c;
            this.jobQueue.reduivy__Job_Handler_Params__c = JQH_Helper.serializeParams(getJobParams());
            this.jobQueue.reduivy__Job_Handler_Record_Ids__c = JQH_Helper.serializeRecordIds(getRecordIds());
            this.jobQueue.reduivy__Source_Record_Id__c = getSourceRecordId();
            this.jobQueue.reduivy__Source_Record_Name__c = getSourceRecordName();
            this.jobQueue.reduivy__Job_Operation_Context__c = getJobOperationContext();
            this.jobQueue.reduivy__Number_of_Attempts__c = 1;

            if (isRetry()) {
                this.jobQueue.reduivy__Number_of_Attempts__c += getLastAttemptCount();
                this.jobQueue.reduivy__Origin_Job_Queue_ID__c = getRetryOriginJobNo();
            }

            //if the config is inactive, we will set the job status to draft for tracking purpose so that admin can retry it
            this.jobQueue.reduivy__Status__c = isExecutable() ? JQH_Helper.STATUS_PENDING : JQH_Helper.STATUS_DRAFT;
            this.jobQueue.reduivy__Job_Queue_Group__c = getJobQueueGroupId();
        }

        return this.jobQueue;

    }

    /**
     * @description Return the job handler Apex type based on the class name
     * @return JQH_JobHandler
     */
    public JQH_JobHandler getJobHandler() {

        if (this.jobHandler == null && getSObject() != null) {

            this.jobHandler = JQH_Helper.getHandlerClass(getSObject().reduivy__Job_Handler_Class_Name__c);
            this.jobHandler.setRecordIds(getRecordIds());
            this.jobHandler.setParams(getJobParams());
        }

        return this.jobHandler;
    }

    /**
     * @description Return job queue config metadata that matches the job operation
     * @return reduivy__Job_Queue_Config__mdt
     */
    public reduivy__Job_Queue_Config__mdt getJobConfig() {

        if (this.jobConfig == null) {
            this.jobConfig = JQH_Helper.getJobOperationSettings(this.jobOperation);
        }

        return this.jobConfig;
    }

    /**
     * @description Return the operation batch size defined in the job queue config metadata
     * @return Integer
     */
    public Integer getBatchSize() {
        if (getJobConfig().reduivy__Job_Handler_Batch_Size__c != null) {
            return Integer.valueOf(getJobConfig().reduivy__Job_Handler_Batch_Size__c);
        }

        return REDU_List_UTIL.DEFAULT_ITERABLE_PAGE_SIZE;
    }

    /**
     * @description Return the list of record ids to be processed
     * @return List<Id>
     */
    public List<Id> getRecordIds() {
        return this.recordIds;
    }

    /**
     * @description Return the deserialized params
     * @return Map<String, Object>
     */
    public Map<String, Object> getParams() {
        return this.params;
    }

    /**
     * @description Return system deserialized params
     */
    public Map<String, Object> getSystemParams() {
        Map<String, Object> sysParams = new Map<String, Object>();

        if (String.isNotBlank(getJobConfig()?.reduivy__Job_Handler_System_Params__c)) {
            sysParams = (Map<String, Object>) JSON.deserializeUntyped(getJobConfig().reduivy__Job_Handler_System_Params__c);
        }

        return sysParams;
    }

    /**
     * @description Return the deserialized params for job combining the params and system params
     * @return Map<String, Object>
     */
    public Map<String, Object> getJobParams() {
        Map<String, Object> jobParams = new Map<String, Object>();

        jobParams.putAll(getParams());
        jobParams.putAll(getSystemParams());

        return jobParams;
    }

    /**
     * @description
     */
    public Boolean hasCallout() {
        if (getJobParams().containsKey(PARAM_HAS_CALLOUT)) {
            Boolean hasCallout = Boolean.valueOf(getJobParams().get(PARAM_HAS_CALLOUT));

            return hasCallout;
        }

        return false;
    }

    /**
     * @description Return true if the job is executable
     */
    public Boolean isExecutable() {
        return getJobConfig()?.reduivy__Active__c;
    }

    /**
     * @description Set job queue group id
     * @param jobQueueGroupId
     */
    public void setJobQueueGroupId(Id jobQueueGroupId) {
        this.jobQueueGroupId = jobQueueGroupId;
    }

    /**
     * @description Get job queue group id
     */
    public Id getJobQueueGroupId() {
        if (String.isNotBlank(this.jobQueue?.reduivy__Job_Queue_Group__c)) {
            return this.jobQueue?.reduivy__Job_Queue_Group__c;
        }

        return this.jobQueueGroupId;
    }
}