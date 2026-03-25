/**
 * @author      WDCi (XiRouh)
 * @date        March 2025
 * @group       Term Offerings Cloning
 * @description 
 * @changehistory
 * ISS-002200 14-03-2025 XiRouh - new class
 * ISS-002364 22-04-2025 XiRouh - Updated to receive the terms name and the additional options, updated to cater to retain or rename the cloned record name
 */
public with sharing class JQH_TermOfferingsCloning_HANDLER implements JQH_JobHandler {
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
    public JQH_TermOfferingsCloning_HANDLER() {
        this.recordIds = new List<Id>();
        this.params = new Map<String, Object>();
    }

    /**
     * @description Return generator class name
     * @return String
     */
    public String getClassName() {
        return 'reduivy.JQH_TermOfferingsCloning_HANDLER';
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
     * @description Study Offering Cloning Job Handler
     * @return JQH_JobManager.HandlerResult
     */
    public JQH_JobManager.HandlerResult execute() {
        
        //init the savepoint for rollback
        SavePoint sp = Database.setSavepoint();

        try {

            if (!this.recordIds.isEmpty()) {
                
                Set<String> sofFields = SOF_Helper.getFieldsForCloning();

                Map<String, Object> sofBindParams = new Map<String, Object>{
                    'recordIds' => this.recordIds
                };

                String sofSoql = 'SELECT ' + String.join(new List<String>(sofFields), ', ') +
                    ' FROM reduivy__Study_Offering__c ' +
                    ' WHERE Id IN :recordIds ';

                List<reduivy__Study_Offering__c> sofRecords = new List<reduivy__Study_Offering__c>();

                for(reduivy__Study_Offering__c sof : (List<reduivy__Study_Offering__c>) Database.queryWithBinds(sofSoql, sofBindParams, AccessLevel.USER_MODE)) {
                    sofRecords.add(sof);
                }

                String currentTermId = this.params.containsKey('currentTermId') ? String.valueOf(this.params.get('currentTermId')) : null;
                
                Boolean cloneStudySession = this.params.containsKey('cloneStudySessionOption') ? Boolean.valueOf(String.valueOf(this.params.get('cloneStudySessionOption'))) : false;
                Boolean selectedRetainStudyOfferingNameOption = this.params.containsKey('selectedRetainStudyOfferingNameOption') ? Boolean.valueOf(String.valueOf(this.params.get('selectedRetainStudyOfferingNameOption'))) : false;
                Boolean selectedRetainStudySessionNameOption = this.params.containsKey('selectedRetainStudySessionNameOption') ? Boolean.valueOf(String.valueOf(this.params.get('selectedRetainStudySessionNameOption'))) : false;
        
                Map<String, String> textsToBeReplaced = new Map<String, String>();
                if(String.isNotBlank(this.params.containsKey('textsToBeReplaced') ? String.valueOf(this.params.get('textsToBeReplaced')) : null)) {
                    textsToBeReplaced = (Map<String, String>) JSON.deserialize(String.valueOf(this.params.get('textsToBeReplaced')), Map<String, String>.class);
                }

                //if study session clone is true, we will use allOrNone=true because partial success is difficult for retry
                Boolean dmlAllOrNone = cloneStudySession;
                //for dml
                List<reduivy__Study_Offering__c> sofRecordsToBeCreated = new List<reduivy__Study_Offering__c>();

                for(reduivy__Study_Offering__c sofToBeCloned: sofRecords) {
                    reduivy__Study_Offering__c tempSof = sofToBeCloned.clone();
                    tempSof.reduivy__Clone_From_Id__c = sofToBeCloned.Id;
                    tempSof.reduivy__Academic_Term__c = currentTermId;

                    if(!selectedRetainStudyOfferingNameOption && !textsToBeReplaced.isEmpty()) {
                        String clonedName = sofToBeCloned.Name;

                        for(String textToReplace : textsToBeReplaced.keySet()) {
                            if(String.isNotBlank(textToReplace) && clonedName.contains(textToReplace)) {
                                clonedName = clonedName.replace(textToReplace, textsToBeReplaced.get(textToReplace));
                            }
                        }

                        tempSof.Name = clonedName;
                    }

                    sofRecordsToBeCreated.add(tempSof);
                }

                //Process the records that need updating
                if(!sofRecordsToBeCreated.isEmpty()) {
                    //this is used for study session cloning - origin sof id vs new sof id
                    Map<Id, Id> originSofIdToNewSofIdMap = new Map<Id, Id>();

                    //Can't use REDU_Database_UTIL to add errors because these aren't trigger records
                    List<Database.SaveResult> createResults = Database.insert(sofRecordsToBeCreated, dmlAllOrNone, AccessLevel.USER_MODE);
            
                    //Track success/failure
                    Integer sofCounter = 0;

                    for (Database.SaveResult sr : createResults){
                        Id originSofId = sofRecordsToBeCreated.get(sofCounter).reduivy__Clone_From_Id__c;

                        if (!sr.isSuccess()) {
                            resultMonitor.addFailResult(originSofId, REDU_Database_UTIL.cleanseErrorMessage(sr.getErrors()[0].getMessage()));
                        }  else {
                            //add the success to the result monitor
                            String successMsg = String.format(Label.Term_Offerings_Cloning_Success_Message, new List<String>{SOF_Helper.getObjectLabel(), sr.getId(), sofRecordsToBeCreated.get(sofCounter).reduivy__Clone_From_Id__c});
                            resultMonitor.addSuccessResult(originSofId, successMsg);
                            originSofIdToNewSofIdMap.put(originSofId, sr.getId());
                        }

                        sofCounter ++;
                    }

                    if (cloneStudySession && !originSofIdToNewSofIdMap.isEmpty()) {
                        performStudySessionsCloning(resultMonitor, originSofIdToNewSofIdMap, selectedRetainStudySessionNameOption, textsToBeReplaced);
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

    /**
     * @description Clone the study sessions and study session times for the related study offerings
     * @param resultMonitor
     * @param originSofIdToNewSofIdMap
     * @return void
     */
    private void performStudySessionsCloning(JQH_JobManager.HandlerResult resultMonitor, Map<Id, Id> originSofIdToNewSofIdMap, Boolean selectedRetainStudySessionNameOption, Map<String, String> textsToBeReplaced){

        Set<String> sseFields = SSE_Helper.getFieldsForCloning();
        Set<String> sstFields = SST_Helper.getFieldsForCloning();

        Map<String, Object> sseBindParams = new Map<String, Object>{
            'originSofIds' => originSofIdToNewSofIdMap.keySet()
        };

        Map<String, Object> sstBindParams = new Map<String, Object>{
            'originSofIds' => originSofIdToNewSofIdMap.keySet()
        };

        String sseSoql = 'SELECT ' + String.join(new List<String>(sseFields), ', ') +
            ' FROM reduivy__Study_Session__c ' +
            ' WHERE reduivy__Study_Offering__c IN :originSofIds ';
        
        String sstSoql = ' SELECT ' + String.join(new List<String>(sstFields), ', ') + 
            ' FROM reduivy__Study_Session_Time__c ' +
            ' WHERE reduivy__Study_Session__r.reduivy__Study_Offering__c IN: originSofIds ';
        
        //for error handling to find back the origin sof id
        Map<Id, Id> originSseIdToOriginSofIdMap = new Map<Id, Id>();
        Map<Id, Id> newSseIdToOriginSofIdMap = new Map<Id, Id>();

        //for study session time cloning
        Map<Id, Id> originSseIdToNewSseIdMap = new Map<Id, Id>();
        //for dml
        List<reduivy__Study_Session__c> sseRecordsToBeCreated = new List<reduivy__Study_Session__c>();
        Map<Id, List<reduivy__Study_Session_Time__c>> sstRecordsTobeCreatedByOriginSseId = new Map<Id, List<reduivy__Study_Session_Time__c>>();

        for (reduivy__Study_Session__c sseTobeCloned : (List<reduivy__Study_Session__c>) Database.queryWithBinds(sseSoql, sseBindParams, AccessLevel.USER_MODE)) {
            if (originSofIdToNewSofIdMap.containsKey(sseTobeCloned.reduivy__Study_Offering__c)) {

                reduivy__Study_Session__c tempSse = sseTobeCloned.clone();
                tempSse.reduivy__Clone_From_Id__c = sseTobeCloned.Id;

                //set the parent lookup field
                tempSse.reduivy__Study_Offering__c = originSofIdToNewSofIdMap.get(sseTobeCloned.reduivy__Study_Offering__c);

                if(!selectedRetainStudySessionNameOption && !textsToBeReplaced.isEmpty()) {
                    String clonedName = sseTobeCloned.Name;

                    for(String textToReplace : textsToBeReplaced.keySet()) {
                        if(String.isNotBlank(textToReplace) && clonedName.contains(textToReplace)) {
                            clonedName = clonedName.replace(textToReplace, textsToBeReplaced.get(textToReplace));
                        }
                    }

                    tempSse.Name = clonedName;
                }

                sseRecordsToBeCreated.add(tempSse);
                originSseIdToOriginSofIdMap.put(sseTobeCloned.Id, sseTobeCloned.reduivy__Study_Offering__c);
                sstRecordsTobeCreatedByOriginSseId.put(sseTobeCloned.Id, new List<reduivy__Study_Session_Time__c>());
            }
        }

        for (reduivy__Study_Session_Time__c sstToBeCloned : (List<reduivy__Study_Session_Time__c>) Database.queryWithBinds(sstSoql, sstBindParams, AccessLevel.USER_MODE)) {
            if (sstRecordsTobeCreatedByOriginSseId.containsKey(sstToBeCloned.reduivy__Study_Session__c)) {
                reduivy__Study_Session_Time__c tempSst = sstToBeCloned.clone();
                tempSst.reduivy__Clone_From_Id__c = sstToBeCloned.Id;

                //set the following fields to null so that it will inherit the dates from new term
                tempSst.reduivy__Change_Date__c = null;
                tempSst.reduivy__Start_Date__c = null;
                tempSst.reduivy__End_Date__c = null;

                if(!selectedRetainStudySessionNameOption && !textsToBeReplaced.isEmpty()) {
                    String clonedName = sstToBeCloned.Name;

                    for(String textToReplace : textsToBeReplaced.keySet()) {
                        if(String.isNotBlank(textToReplace) && clonedName.contains(textToReplace)) {
                            clonedName = clonedName.replace(textToReplace, textsToBeReplaced.get(textToReplace));
                        }
                    }

                    tempSst.Name = clonedName;
                }

                sstRecordsTobeCreatedByOriginSseId.get(sstToBeCloned.reduivy__Study_Session__c).add(tempSst);
            }
        }

        if (!sseRecordsToBeCreated.isEmpty()) {
            //use allOrNone=true to make error handling simpler
            List<Database.SaveResult> sseCreateResults = Database.insert(sseRecordsToBeCreated, true, AccessLevel.USER_MODE);
            
            //Track success/failure
            Integer sseCounter = 0;

            for (Database.SaveResult sr : sseCreateResults){
                Id originSseId = sseRecordsToBeCreated.get(sseCounter).reduivy__Clone_From_Id__c;

                if (!sr.isSuccess()) {
                    resultMonitor.addFailResult(originSseIdToOriginSofIdMap.get(originSseId), REDU_Database_UTIL.cleanseErrorMessage(sr.getErrors()[0].getMessage()));
                    
                    //remove the error records from the map so that we don't need to clone the related study session times
                    sstRecordsTobeCreatedByOriginSseId.remove(originSseId);

                }  else {
                    //add the success to the result monitor
                    String successMsg = String.format(Label.Term_Offerings_Cloning_Success_Message, new List<String>{SSE_Helper.getObjectLabel(), sr.getId(), sseRecordsToBeCreated.get(sseCounter).reduivy__Clone_From_Id__c});
                    resultMonitor.addSuccessResult(originSseIdToOriginSofIdMap.get(originSseId), successMsg);

                    originSseIdToNewSseIdMap.put(originSseId, sr.getId());
                    newSseIdToOriginSofIdMap.put(sr.getId(), originSseIdToOriginSofIdMap.get(originSseId));
                }

                sseCounter ++;
            }

            List<reduivy__Study_Session_Time__c> sstRecordsToBeCreated = new List<reduivy__Study_Session_Time__c>();
            for (Id originSseId : sstRecordsTobeCreatedByOriginSseId.keySet()) {
                if (originSseIdToNewSseIdMap.containsKey(originSseId)) {
                    for (reduivy__Study_Session_Time__c newSst : sstRecordsTobeCreatedByOriginSseId.get(originSseId)) {
                        //set the parent lookup field
                        newSst.reduivy__Study_Session__c = originSseIdToNewSseIdMap.get(originSseId);

                        sstRecordsToBeCreated.add(newSst);
                    }
                }
            }

            if (!sstRecordsToBeCreated.isEmpty()) {
                //use allOrNone=true to make error handling simpler
                List<Database.SaveResult> sstCreateResults = Database.insert(sstRecordsToBeCreated, true, AccessLevel.USER_MODE);
            
                //Track success/failure
                Integer sstCounter = 0;

                for (Database.SaveResult sr : sstCreateResults){
                    Id newSseId = sstRecordsToBeCreated.get(sstCounter).reduivy__Study_Session__c;

                    if (!sr.isSuccess()) {
                        resultMonitor.addFailResult(newSseIdToOriginSofIdMap.get(newSseId), REDU_Database_UTIL.cleanseErrorMessage(sr.getErrors()[0].getMessage()));
                        
                    }  else {
                        //add the success to the result monitor
                        String successMsg = String.format(Label.Term_Offerings_Cloning_Success_Message, new List<String>{SST_Helper.getObjectLabel(), sr.getId(), sstRecordsToBeCreated.get(sstCounter).reduivy__Clone_From_Id__c});
                        resultMonitor.addSuccessResult(newSseIdToOriginSofIdMap.get(newSseId), successMsg);
                    }

                    sstCounter ++;
                }
            }
        }
    }
}