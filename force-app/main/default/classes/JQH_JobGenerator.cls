/**
 * @author      WDCi (Lean)
 * @date        Dec 2024
 * @group       Job Queue Framework
 * @description The job generator interface
 * @changehistory
 * ISS-002219 18-12-2024 Lean - new class
 */
global interface JQH_JobGenerator {
    
    String getClassName();

    String getClassInstanceDetails();
    
    void setRecordIds(List<Id> recordIds);
    
    void setParams(Map<String, Object> params);

    void setJobConfig(reduivy__Job_Queue_Config__mdt jobConfig);

    List<JQH_JobManager.GeneratorResult> execute();
    
}