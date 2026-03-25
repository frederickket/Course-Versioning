/**
 * @author      WDCi (Lean)
 * @date        Jan 2025
 * @group       Job Queue Framework
 * @description The sample job handler to simulate error for error handling
 * @changehistory
 * ISS-002219 03-01-2025 Lean - new class
 */
public with sharing class JQH_SampleError_HANDLER implements reduivy.JQH_JobHandler {
    
    /**
     * @description List of record ids
     */
    private List<Id> recordIds;

    /**
     * @description Map of params
     */
    private Map<String, Object> params;

    /**
     * @description Default constructor
     */
    public JQH_SampleError_HANDLER() {
        this.recordIds = new List<Id>();
        this.params = new Map<String, Object>();
    }

    /**
     * @description Return generator class name
     * @return String
     */
    public String getClassName() {
        return 'reduivy.JQH_SampleError_HANDLER';
    }

    /**
     * @description Return handler class instance details
     * @return String
     */
    public String getClassInstanceDetails() {
        return String.valueOf(this);
    }

    /**
     * @description Set record ids to be processed
     * @param recordIds List of record id
     * @return void
     */
    public void setRecordIds(List<Id> recordIds) {
        this.recordIds = recordIds;
    }

    /**
     * @description Set parameters for the handler
     * @param params Map of params in key value pair
     * @return void
     */
    public void setParams(Map<String, Object> params) {
        this.params = params;
    }

    /**
     * @description Release grade
     * @return JQH_JobManager.HandlerResult
     */
    public reduivy.JQH_JobManager.HandlerResult execute() {

        if (this.params.containsKey('warningtest')) {
            //init the result monitor
            reduivy.JQH_JobManager.HandlerResult resultMonitor = new reduivy.JQH_JobManager.HandlerResult();

            for (Id recId : this.recordIds) {
                resultMonitor.addWarningResult(recId, 'This is a warning test.');
            }

            return resultMonitor;
            
        } else {
            throw new reduivy.REDU_ApplicationException('This is an exception.');
        }
    }
}