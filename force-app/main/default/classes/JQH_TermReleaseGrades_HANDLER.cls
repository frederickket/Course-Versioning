/**
 * @author      WDCi (XiRouh)
 * @date        March 2025
 * @group       Term Release Grades
 * @description This job handler will set Release Grades on the given individual enrollments
 * @changehistory
 * ISS-002311 06-03-2025 XiRouh - new class
 */
public with sharing class JQH_TermReleaseGrades_HANDLER implements JQH_JobHandler {
    
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
    public JQH_TermReleaseGrades_HANDLER() {
        this.recordIds = new List<Id>();
        this.params = new Map<String, Object>();
    }

    /**
     * @description Return generator class name
     * @return String
     */
    public String getClassName() {
        return 'reduivy.JQH_TermReleaseGrades_HANDLER';
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
    JQH_JobManager.HandlerResult resultMonitor = new JQH_JobManager.HandlerResult();

    /**
     * @description Release grade
     * @return JQH_JobManager.HandlerResult
     */
    public JQH_JobManager.HandlerResult execute() {
        
        //init the savepoint for rollback
        SavePoint sp = Database.setSavepoint();

        try {
            //build logic here to process the records
            if (!this.recordIds.isEmpty()) {
                Set<String> fields = new Set<String>{
                    'Id',
                    'Name',
                    'reduivy__Grade_Release_Status__c',
                    'reduivy__Grade_Result__c',
                    'reduivy__Credit_Transfer_Received__c'
                };

                String soql = 'SELECT ' + String.join(fields, ', ') + 
                    ' FROM reduivy__Individual_Enrollment__c ' + 
                    ' WHERE Id IN: recordIds';

                this.params.put('recordIds', this.recordIds);
                
                String selectedGradeReleaseStatus = this.params.containsKey('selectedGradeReleaseStatus') ? String.valueOf(this.params.get('selectedGradeReleaseStatus')) : null;

                List<reduivy__Individual_Enrollment__c> ienUpdateList = new List<reduivy__Individual_Enrollment__c>();
                String ctaObjectLabel = CTA_Helper.getObjectLabel();

                for (reduivy__Individual_Enrollment__c ien : (List<reduivy__Individual_Enrollment__c>) Database.queryWithBinds(soql, this.params, AccessLevel.USER_MODE)) {

                    if(ien.reduivy__Credit_Transfer_Received__c) {
                        resultMonitor.addWarningResult(ien.Id, String.format(Label.Term_Grade_Release_IEN_Originates_From_Credit_Transfer_Application,
                            new List<String>{ctaObjectLabel}));

                        continue;
                    }
                    
                    if(ien.reduivy__Grade_Release_Status__c == selectedGradeReleaseStatus) {
                        resultMonitor.addWarningResult(ien.Id, String.format(Label.Term_Grade_Release_IEN_Already_In_Selected_Release_Status, new List<String>{selectedGradeReleaseStatus}));
                        continue;
                    }

                    //Update the field
                    ien.reduivy__Grade_Release_Status__c = selectedGradeReleaseStatus;
                    ienUpdateList.add(ien);

                }

                //Process the records that need updating
                if(!ienUpdateList.isEmpty()) {
                    //Can't use REDU_Database_UTIL to add errors because these aren't trigger records
                    List<Database.SaveResult> updateResults = Database.update(ienUpdateList, false, AccessLevel.USER_MODE);
            
                    //Track success/failure
                    Integer counter = 0;
                    for (Database.SaveResult sr : updateResults){
                        if (!sr.isSuccess()) {
                            resultMonitor.addFailResult(ienUpdateList.get(counter).Id, REDU_Database_UTIL.cleanseErrorMessage(sr.getErrors()[0].getMessage()));
                        }  else {
                            //add the success to the result monitor
                            resultMonitor.addSuccessResult(ienUpdateList.get(counter).Id, Label.Success);
                        }

                        counter ++;
                    }
                }
            }
        } catch (Exception exp) {
            //rollback if there is an exception
            Database.rollback(sp);

            //add the error to the result monitor
            for (Id recordId : recordIds) {
                String errorMsg = String.format(Label.All_Changes_Have_Been_Rolled_Back_Due_To_Error, new List<String>{REDU_Database_UTIL.cleanseErrorMessage(exp.getMessage()), exp.getStackTraceString()});
                resultMonitor.addFailResult(recordId, errorMsg);
            }
        }

        // return the result monitor
        return resultMonitor;
    }
}