/**
 * @author      WDCi (XiRouh)
 * @date        March 2025
 * @group       Term Release Grades
 * @description This job generator will set Release Grades on the selected study Offerings
 *              to trigger Release Grades on related individual enrollment.
 * @changehistory
 * ISS-002311 05-03-2024 XiRouh - new class
 */
public with sharing class JQH_TermReleaseGrades_GENERATOR implements JQH_JobGenerator {
    
    List<Id> recordIds;
    Map<String, Object> params;
    reduivy__Job_Queue_Config__mdt jobConfig;

    public JQH_TermReleaseGrades_GENERATOR () {

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
        return 'reduivy.JQH_TermReleaseGrades_GENERATOR';
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
    public List<JQH_JobManager.GeneratorResult> execute() {
        //init the results list
        List<JQH_JobManager.GeneratorResult> results = new List<JQH_JobManager.GeneratorResult>();

        String jobOperationContext = this.params.containsKey(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT) ? String.valueOf(this.params.get(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT)) : null;
        String selectedGradeReleaseStatus = this.params.containsKey('selectedGradeReleaseStatus') ? String.valueOf(this.params.get('selectedGradeReleaseStatus')) : null;

        List<reduivy__Study_Offering__c> sofList = new List<reduivy__Study_Offering__c>();
        Set<Id> sofIds = new Set<Id>();
        for(reduivy__Study_Offering__c sof : [SELECT Id, 
            Name 
            FROM reduivy__Study_Offering__c 
            WHERE Id IN :this.recordIds 
            WITH USER_MODE
            ORDER BY reduivy__Code__c ASC NULLS LAST, Name ASC
        ]) {
            sofList.add(sof);
            sofIds.add(sof.Id);
        }

        List<String> ienStatuses = new List<String>();
        ienStatuses.addAll(IEN_Helper.getInProgressStatuses());
        ienStatuses.addAll(IEN_Helper.getCompletedStatuses());

        Map<String, Object> ienBindParams = new Map<String, Object>{
            'sofIds' => sofIds,
            'recordTypeId' => IEN_Helper.getStudentRecordTypeId(),
            'enrollmentStatuses' => ienStatuses
        };

        String ienSoql = 'SELECT Id, reduivy__Study_Offering__c ' +
            ' FROM reduivy__Individual_Enrollment__c ' +
            ' WHERE reduivy__Enrollment_Status__c IN :enrollmentStatuses ' +
            ' AND RecordTypeId = :recordTypeId ' +
            ' AND reduivy__Study_Offering__c IN :sofIds '; 

        Map<Id, List<Id>> ienIdsBySof = new Map<Id, List<Id>>();
        for(reduivy__Individual_Enrollment__c ien : (List<reduivy__Individual_Enrollment__c>) Database.queryWithBinds(ienSoql, ienBindParams, AccessLevel.USER_MODE)) {
            if(!ienIdsBySof.containsKey(ien.reduivy__Study_Offering__c)) {
                ienIdsBySof.put(ien.reduivy__Study_Offering__c, new List<Id>());
            }

            ienIdsBySof.get(ien.reduivy__Study_Offering__c).add(ien.Id);
        }

        if(!ienIdsBySof.isEmpty()) {
            for(reduivy__Study_Offering__c sof : sofList) {
                JQH_JobManager.GeneratorResult result = new JQH_JobManager.GeneratorResult();
                
                result.params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_ID, sof.Id);
                result.params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_NAME, sof.Name);
                if (String.isNotBlank(jobOperationContext)) {
                    result.params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, jobOperationContext);
                }
                
                //additional params for your handler
                result.recordIds = ienIdsBySof.containsKey(sof.Id) ? ienIdsBySof.get(sof.Id) : new List<Id>();
                result.params.put('selectedGradeReleaseStatus', selectedGradeReleaseStatus);
                
                results.add(result);   
            }
        }

        return results;
    }

}