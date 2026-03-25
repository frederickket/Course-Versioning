/**
 * @author      WDCi (Lean)
 * @date        July 2025
 * @group       Job Queue Framework
 * @description To rollup the statistics to job queue group
 * @changehistory
 * ISS-002547 10-07-2025 Lean - new trigger
 */
public without sharing class JQH_QueueGroupRollup_EXE extends REDU_TriggerExecutable {
    
    /**
     * @description AfterInsert
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterInsert(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            List<reduivy__Job_Queue__c> workingList = new List<reduivy__Job_Queue__c>();
            for (reduivy__Job_Queue__c jqhNew : (List<reduivy__Job_Queue__c>) newList) {

                if (jqhNew.reduivy__Status__c != JQH_Helper.STATUS_DRAFT 
                    && String.isNotBlank(jqhNew.reduivy__Job_Queue_Group__c)
                ) {
                    workingList.add(jqhNew);
                }
            }

            doRollup(workingList);
        }
    }

    /**
     * @description AfterUpdate
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterUpdate(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            List<reduivy__Job_Queue__c> workingList = new List<reduivy__Job_Queue__c>();
            for (reduivy__Job_Queue__c jqhNew : (List<reduivy__Job_Queue__c>) newList) {
                reduivy__Job_Queue__c jqhOld = (reduivy__Job_Queue__c) oldMap.get(jqhNew.Id);

                if (jqhNew.reduivy__Status__c != jqhOld.reduivy__Status__c
                    && String.isNotBlank(jqhNew.reduivy__Job_Queue_Group__c)
                ) {
                    workingList.add(jqhNew);
                }
            }

            doRollup(workingList);
        }
    }

    /**
     * @description AfterDelete
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterDelete(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            List<reduivy__Job_Queue__c> workingList = new List<reduivy__Job_Queue__c>();
            for (reduivy__Job_Queue__c jqhOld : (List<reduivy__Job_Queue__c>) oldList) {

                if (jqhOld.reduivy__Status__c != JQH_Helper.STATUS_DRAFT
                    && String.isNotBlank(jqhOld.reduivy__Job_Queue_Group__c)
                ) {
                    workingList.add(jqhOld);
                }
            }

            doRollup(workingList);
        }
    }

    /**
     * @description AfterUndelete
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterUndelete(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            List<reduivy__Job_Queue__c> workingList = new List<reduivy__Job_Queue__c>();
            for (reduivy__Job_Queue__c jqhNew : (List<reduivy__Job_Queue__c>) newList) {

                if (jqhNew.reduivy__Status__c != JQH_Helper.STATUS_DRAFT
                    && String.isNotBlank(jqhNew.reduivy__Job_Queue_Group__c)
                ) {
                    workingList.add(jqhNew);
                }
            }

            doRollup(workingList);
        }
    }
	
    /**
     * @description Rollup the statistics to job queue group
     * @param jobQueueList
     * @return void
     */
    private void doRollup(List<reduivy__Job_Queue__c> jobQueueList) {
        
        if (!jobQueueList.isEmpty()) {
            
            Map<Id, List<reduivy__Job_Queue__c>> jobQueueByGroup = new Map<Id, List<reduivy__Job_Queue__c>>();
            for (reduivy__Job_Queue__c jqh : jobQueueList) {
                if (!jobQueueByGroup.containsKey(jqh.reduivy__Job_Queue_Group__c)) {
                    jobQueueByGroup.put(jqh.reduivy__Job_Queue_Group__c, new List<reduivy__Job_Queue__c>());
                }

                jobQueueByGroup.get(jqh.reduivy__Job_Queue_Group__c).add(jqh);
            }

            Set<String> jqhStatuses = new Set<String> {
                JQH_Helper.STATUS_PENDING,
                JQH_Helper.STATUS_PROCESSING,
                JQH_Helper.STATUS_COMPLETED,
                JQH_Helper.STATUS_FAILED,
                JQH_Helper.STATUS_CANCELLED
            };

            Set<String> jqgFields = new Set<String>{
                'Id',
                'reduivy__Total_Jobs__c',
                'reduivy__Completed_Jobs__c',
                'reduivy__Failed_Jobs__c',
                'reduivy__Cancelled_Jobs__c',
                'reduivy__Total_Records__c',
                'reduivy__Success_Records__c',
                'reduivy__Error_Records__c',
                'reduivy__Warning_Records__c',
                'reduivy__Start_Datetime__c',
                'reduivy__End_Datetime__c',
                'reduivy__Status__c'
            };

            Set<String> jqhFields = new Set<String>{
                'reduivy__Number_of_Records__c',
                'reduivy__Number_of_Success_Records__c',
                'reduivy__Number_of_Error_Records__c',
                'reduivy__Number_of_Warning_Records__c',
                'reduivy__Status__c',
                'reduivy__Start_Datetime__c',
                'reduivy__End_Datetime__c'
            };

            Map<String, Object> jqgBindParams = new Map<String, Object>();
            jqgBindParams.put('jqgIds', jobQueueByGroup.keySet());
            jqgBindParams.put('jqhStatuses', jqhStatuses);

            String jqgSoql = 'SELECT ' + String.join(jqgFields, ', ') + ', ' +
                ' (SELECT ' + String.join(jqhFields, ', ') + ' FROM reduivy__Job_Queues__r WHERE reduivy__Status__c IN: jqhStatuses) ' +
                ' FROM reduivy__Job_Queue_Group__c ' +
                ' WHERE Id IN: jqgIds ';
            
            Map<String, Set<String>> objectFls = new Map<String, Set<String>>();
            objectFls.put(JQH_Helper.getApiName(), jqhFields);
            objectFls.put(JQG_Helper.getApiName(), jqgFields);

            List<reduivy__Job_Queue_Group__c> jobQueueGroupUpdateList = new List<reduivy__Job_Queue_Group__c>();
            for (reduivy__Job_Queue_Group__c jqg : (List<reduivy__Job_Queue_Group__c>) REDU_SystemMode_UTIL.doQuery(jqgSoql, jqgBindParams, objectFls)) {
                Decimal totalJobs = 0;
                Decimal completedJobs = 0;
                Decimal cancelledJobs = 0;
                Decimal failedJobs = 0;
                Decimal pendingJobs = 0;
                Decimal processingJobs = 0;

                Decimal totalRecords = 0;
                Decimal successRecords = 0;
                Decimal errorRecords = 0;
                Decimal warningRecords = 0;

                Datetime firstStart;
                Datetime lastEnd;

                String jobQueueGroupStatus = JQG_Helper.STATUS_PENDING;

                for (reduivy__Job_Queue__c jqh : jqg.reduivy__Job_Queues__r) {
                    totalJobs ++;
                    totalRecords += (jqh.reduivy__Number_of_Records__c ?? 0);

                    if (jqh.reduivy__Status__c == JQH_Helper.STATUS_COMPLETED) {
                        completedJobs ++;
                    } else if (jqh.reduivy__Status__c == JQH_Helper.STATUS_CANCELLED) {
                        cancelledJobs ++;
                    } else if (jqh.reduivy__Status__c == JQH_Helper.STATUS_FAILED) {
                        failedJobs ++;                        
                    } else if (jqh.reduivy__Status__c == JQH_Helper.STATUS_PENDING) {
                        pendingJobs ++;
                    } else if (jqh.reduivy__Status__c == JQH_Helper.STATUS_PROCESSING) {
                        processingJobs ++;
                    }

                    if (jqh.reduivy__Status__c == JQH_Helper.STATUS_COMPLETED || jqh.reduivy__Status__c == JQH_Helper.STATUS_FAILED) {
                        //we won't include the record count for success, warning, error if the job is cancelled.
                        successRecords += (jqh.reduivy__Number_of_Success_Records__c ?? 0);
                        errorRecords += (jqh.reduivy__Number_of_Error_Records__c ?? 0);
                        warningRecords += (jqh.reduivy__Number_of_Warning_Records__c ?? 0);

                        if (firstStart == null || firstStart > jqh.reduivy__Start_Datetime__c) {
                            firstStart = jqh.reduivy__Start_Datetime__c;
                        }

                        if (lastEnd == null || lastEnd < jqh.reduivy__End_Datetime__c) {
                            lastEnd = jqh.reduivy__End_Datetime__c;
                        }
                    }
                }

                if (totalJobs == pendingJobs) {
                    jobQueueGroupStatus = JQG_Helper.STATUS_PENDING;
                } else if (processingJobs > 0) {
                    jobQueueGroupStatus = JQG_Helper.STATUS_PROCESSING;
                } else if (totalJobs == (completedJobs + failedJobs + cancelledJobs)) {
                    if (failedJobs > 0) {
                        jobQueueGroupStatus = JQG_Helper.STATUS_FAILED;
                    } else if (completedJobs > 0) {
                        jobQueueGroupStatus = JQG_Helper.STATUS_COMPLETED;
                    } else if (totalJobs == cancelledJobs) {
                        jobQueueGroupStatus = JQG_Helper.STATUS_CANCELLED;
                    }
                }

                if (jqg.reduivy__Total_Jobs__c != totalJobs ||
                    jqg.reduivy__Completed_Jobs__c != completedJobs ||
                    jqg.reduivy__Failed_Jobs__c != failedJobs ||
                    jqg.reduivy__Cancelled_Jobs__c != cancelledJobs ||
                    jqg.reduivy__Total_Records__c != totalRecords ||
                    jqg.reduivy__Success_Records__c != successRecords ||
                    jqg.reduivy__Error_Records__c != errorRecords ||
                    jqg.reduivy__Warning_Records__c != warningRecords ||
                    jqg.reduivy__Start_Datetime__c != firstStart ||
                    jqg.reduivy__End_Datetime__c != lastEnd ||
                    jqg.reduivy__Status__c != jobQueueGroupStatus
                ) {
                    reduivy__Job_Queue_Group__c jqgUpdate = new reduivy__Job_Queue_Group__c(Id = jqg.Id);
                    jqgUpdate.reduivy__Total_Jobs__c = totalJobs;
                    jqgUpdate.reduivy__Completed_Jobs__c = completedJobs;
                    jqgUpdate.reduivy__Failed_Jobs__c = failedJobs;
                    jqgUpdate.reduivy__Cancelled_Jobs__c = cancelledJobs;
                    jqgUpdate.reduivy__Total_Records__c = totalRecords;
                    jqgUpdate.reduivy__Success_Records__c = successRecords;
                    jqgUpdate.reduivy__Error_Records__c = errorRecords;
                    jqgUpdate.reduivy__Warning_Records__c = warningRecords;
                    jqgUpdate.reduivy__Start_Datetime__c = firstStart;
                    jqgUpdate.reduivy__End_Datetime__c = lastEnd;

                    //we only change the status if it is not being cancelled half way through
                    if (jqg.reduivy__Status__c != JQG_Helper.STATUS_CANCELLED) {
                        jqgUpdate.reduivy__Status__c = jobQueueGroupStatus;
                    }

                    jobQueueGroupUpdateList.add(jqgUpdate);
                }
            }

            if (!jobQueueGroupUpdateList.isEmpty()) {
                REDU_Database_UTIL.doUpdate(jobQueueGroupUpdateList, jobQueueByGroup, 'Id', false);
            }
        }
    }
}