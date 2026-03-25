/**
 * @author      WDCi (Lean)
 * @date        Dec 2024
 * @group       Job Queue Framework
 * @description The sample job handler to simulate the grade release
 * @changehistory
 * ISS-002219 11-12-2024 Lean - new class
 */
public with sharing class JQH_Sample_HANDLER implements reduivy.JQH_JobHandler {
    
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
    public JQH_Sample_HANDLER() {
        this.recordIds = new List<Id>();
        this.params = new Map<String, Object>();
    }

    /**
     * @description Return generator class name
     * @return String
     */
    public String getClassName() {
        return 'reduivy.JQH_Sample_HANDLER';
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

    //init the result monitor
    reduivy.JQH_JobManager.HandlerResult resultMonitor = new reduivy.JQH_JobManager.HandlerResult();
    
    /**
     * @description Release grade
     * @return JQH_JobManager.HandlerResult
     */
    public reduivy.JQH_JobManager.HandlerResult execute() {
        
        //init the savepoint for rollback
        SavePoint sp = Database.setSavepoint();

        try {
            //build logic here to process the records
            if (!this.recordIds.isEmpty()) {
                Set<String> fields = new Set<String>{
                    'Id',
                    'Name',
                    'reduivy__Grade_Release_Status__c'
                };

                String soql = 'SELECT ' + String.join(fields, ', ') + 
                    ' FROM reduivy__Individual_Enrollment__c ' + 
                    ' WHERE Id IN: recordIds' + 
                    ' AND reduivy__Enrollment_Status__c =: enrollmentStatus ';

                this.params.put('recordIds', this.recordIds);
                
                Boolean testGradeUpdate = this.params.containsKey('testGradeUpdate') ? Boolean.valueOf(this.params.get('testGradeUpdate')) : false;
                String gradeReleaseStatus = this.params.containsKey('gradeReleaseStatus') ? String.valueOf(this.params.get('gradeReleaseStatus')) : '';

                List<reduivy__Individual_Enrollment__c> ienUpdateList = new List<reduivy__Individual_Enrollment__c>();
                for (reduivy__Individual_Enrollment__c ien : (List<reduivy__Individual_Enrollment__c>) Database.queryWithBinds(soql, this.params, AccessLevel.USER_MODE)) {

                    //we only test the update scenario from JQH_JobWorker_TEST
                    if (testGradeUpdate) {
                        if (ien.reduivy__Grade_Release_Status__c != gradeReleaseStatus) {
                            ien.reduivy__Grade_Release_Status__c = reduivy.IEN_Helper.GRADE_RELEASE_STATUS_RELEASED;

                            ienUpdateList.add(ien);
                        }
                    }
                }

                reduivy.REDU_Database_UTIL.doUpdate(ienUpdateList, new Map<Id, reduivy__Individual_Enrollment__c>(ienUpdateList), 'Id', false);

                for (reduivy__Individual_Enrollment__c ien : ienUpdateList) {
                    
                    //add the error to the result monitor
                    if (!ien.getErrors().isEmpty()) {
                        resultMonitor.addFailResult(ien.Id, ien.getErrors()[0].getMessage());
                    } else {
                        resultMonitor.addSuccessResult(ien.Id, 'Success.');
                    }
                }
            }
        } catch (Exception exp) {

            //rollback if there is an exception
            Database.rollback(sp);

            //add the error to the result monitor
            for (Id recordId : recordIds) {
                String errorMsg = String.format(Label.reduivy.All_Changes_Have_Been_Rolled_Back_Due_To_Error, new List<String>{reduivy.REDU_Database_UTIL.cleanseErrorMessage(exp.getMessage()), exp.getStackTraceString()});
                resultMonitor.addFailResult(recordId, errorMsg);
            }

        }

        // return the result monitor
        return resultMonitor;
    }
}