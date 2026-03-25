/**
 * @author      WDCi (Lean)
 * @date        Dec 2024
 * @group       Job Queue Framework
 * @description The job handler interface
 * @changehistory
 * ISS-002219 11-12-2024 Lean - new class
 */
global interface JQH_JobHandler {
    
    String getClassName();

    String getClassInstanceDetails();

    void setRecordIds(List<Id> recordIds);

    void setParams(Map<String, Object> params);

    JQH_JobManager.HandlerResult execute();
}