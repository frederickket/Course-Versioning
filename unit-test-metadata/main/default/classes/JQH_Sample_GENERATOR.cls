/**
 * @author      WDCi (Lean)
 * @date        Dec 2024
 * @group       Job Queue Framework
 * @description The sample job generator to simulate grade release data compiler
 * @changehistory
 * ISS-002219 19-12-2024 Lean - new class
 */
public with sharing class JQH_Sample_GENERATOR implements reduivy.JQH_JobGenerator {
    
    List<Id> recordIds;
    Map<String, Object> params;
    reduivy__Job_Queue_Config__mdt jobConfig;

    public JQH_Sample_GENERATOR() {

    }

    /**
     * @description Set record ids to be queried
     * @param recordIds List of record id
     * @return void
     */
    public void setRecordIds(List<Id> recordIds) {
        this.recordIds = recordIds;
    }

    /**
     * @description Set parameters for the generator
     * @param params Map of params in key value pair
     * @return void
     */
    public void setParams(Map<String, Object> params) {
        this.params = params;
    }

    /**
     * @description Set job config for the generator
     * @param params Map of params in key value pair
     * @return void
     */
    public void setJobConfig(reduivy__Job_Queue_Config__mdt jobConfig) {
        this.jobConfig = jobConfig;
    }

    /**
     * @description Return generator class name
     * @return String
     */
    public String getClassName() {
        return 'reduivy.JQH_Sample_GENERATOR';
    }

    /**
     * @description Return generator class instance details
     * @return String
     */
    public String getClassInstanceDetails() {
        return String.valueOf(this);
    }

    /**
     * @description Execute
     */
    public List<reduivy.JQH_JobManager.GeneratorResult> execute() {

        //init the results list
        List<reduivy.JQH_JobManager.GeneratorResult> results = new List<reduivy.JQH_JobManager.GeneratorResult>();

        String jobOperationContext = this.params.containsKey(reduivy.JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT) ? String.valueOf(this.params.get(reduivy.JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT)) : null;

        //query data based on the provided record ids
        for (reduivy__Study_Offering__c sof : [SELECT Id,
            Name,
            (
                SELECT Id
                FROM reduivy__Individual_Enrollments__r
                WHERE RecordTypeId =: reduivy.IEN_Helper.getStudentRecordTypeId()
            )
            FROM reduivy__Study_Offering__c
            WHERE Id IN: this.recordIds
            WITH USER_MODE
        ]) {

            List<Id> recordIds = new List<Id>();
            for (reduivy__Individual_Enrollment__c ien : sof.reduivy__Individual_Enrollments__r) {
                recordIds.add(ien.Id);
            }

            if (!recordIds.isEmpty()) {
                //compile the result, each result represents 1 job
                reduivy.JQH_JobManager.GeneratorResult result = new reduivy.JQH_JobManager.GeneratorResult();
                
                //optional system param
                result.params.put(reduivy.JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_ID, sof.Id);
                result.params.put(reduivy.JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_NAME, sof.Name);
                
                if (String.isNotBlank(jobOperationContext)) {
                    result.params.put(reduivy.JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, jobOperationContext);
                }

                //additional params for your handler
                result.params.put('enrollmentStatus', 'Enrolled');
                result.recordIds = recordIds;
                
                results.add(result);
            }
        }

        return results;
    }
}