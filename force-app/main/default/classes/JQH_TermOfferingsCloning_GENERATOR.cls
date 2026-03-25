/**
 * @author      WDCi (XiRouh)
 * @date        March 2025
 * @group       Term Offerings Cloning
 * @description 
 * @changehistory
 * ISS-002200 14-03-2025 XiRouh - new class
 * ISS-002364 22-04-2025 XiRouh - Updated to receive the terms name and the additional options
 */
public with sharing class JQH_TermOfferingsCloning_GENERATOR implements JQH_JobGenerator {
    List<Id> recordIds;
    Map<String, Object> params;
    reduivy__Job_Queue_Config__mdt jobConfig;

    public JQH_TermOfferingsCloning_GENERATOR () {

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
        return 'reduivy.JQH_TermOfferingsCloning_GENERATOR';
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
        
        String currentTermId = this.params.containsKey('currentTermId') ? String.valueOf(this.params.get('currentTermId')) : null;
        String selectedCampusId = this.params.containsKey('selectedCampusId') ? String.valueOf(this.params.get('selectedCampusId')) : null;
        String selectedTermId = this.params.containsKey('selectedTermId') ? String.valueOf(this.params.get('selectedTermId')) : null;
        
        String studyOfferingStatuses = this.params.containsKey('studyOfferingStatuses') ? String.valueOf(this.params.get('studyOfferingStatuses')) : null;
        
        Boolean cloneStudySessionOption = this.params.containsKey('cloneStudySessionOption') ? Boolean.valueOf(String.valueOf(this.params.get('cloneStudySessionOption'))) : false;
        Boolean selectedRetainStudyOfferingNameOption = this.params.containsKey('selectedRetainStudyOfferingNameOption') ? Boolean.valueOf(String.valueOf(this.params.get('selectedRetainStudyOfferingNameOption'))) : false;
        Boolean selectedRetainStudySessionNameOption = this.params.containsKey('selectedRetainStudySessionNameOption') ? Boolean.valueOf(String.valueOf(this.params.get('selectedRetainStudySessionNameOption'))) : false;

        String textsToBeReplaced = this.params.containsKey('textsToBeReplaced') ? String.valueOf(this.params.get('textsToBeReplaced')) : null;

        Map<Id, List<Id>> sunIdWithSofList = new Map<Id, List<Id>>();
        Map<Id, String> sunIdWithSunName = new Map<Id, String>();

        Set<String> sofStatusesSet = new Set<String>(studyOfferingStatuses.split(';'));

        for(reduivy__Study_Offering__c sof : [
            SELECT Id, reduivy__Study_Unit__c, reduivy__Study_Unit__r.Name 
            FROM reduivy__Study_Offering__c 
            WHERE reduivy__Study_Unit__c IN :this.recordIds
            AND reduivy__Academic_Term__c = :selectedTermId
            AND reduivy__Campus__c = :selectedCampusId
            AND reduivy__Status__c IN :sofStatusesSet
            WITH USER_MODE
        ]) {
            if(!sunIdWithSofList.containsKey(sof.reduivy__Study_Unit__c)) {
                sunIdWithSofList.put(sof.reduivy__Study_Unit__c, new List<Id>());
            }

            sunIdWithSofList.get(sof.reduivy__Study_Unit__c).add(sof.Id);

            if(!sunIdWithSunName.containsKey(sof.reduivy__Study_Unit__c)) {
                sunIdWithSunName.put(sof.reduivy__Study_Unit__c, sof.reduivy__Study_Unit__r.Name);
            }
        }

        for(Id sunId : sunIdWithSofList.keySet()) {
            JQH_JobManager.GeneratorResult result = new JQH_JobManager.GeneratorResult();
                
            result.params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_ID, sunId);
            result.params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_NAME, sunIdWithSunName.get(sunId));
            if (String.isNotBlank(jobOperationContext)) {
                result.params.put(JQH_JobQueue_OBJ.PARAM_JOB_OPERATION_CONTEXT, jobOperationContext);
            }
            
            //additional params for your handler
            result.recordIds = sunIdWithSofList.containsKey(sunId) ? sunIdWithSofList.get(sunId) : new List<Id>();
            result.params.put('currentTermId', currentTermId);

            result.params.put('cloneStudySessionOption', cloneStudySessionOption);
            result.params.put('selectedRetainStudyOfferingNameOption', selectedRetainStudyOfferingNameOption);
            result.params.put('selectedRetainStudySessionNameOption', selectedRetainStudySessionNameOption);

            result.params.put('textsToBeReplaced', textsToBeReplaced);

            results.add(result);   
        }

        return results;
    }
}