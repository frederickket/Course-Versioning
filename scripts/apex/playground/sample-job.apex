delete [SELECT Id FROM reduivy__Log__c];
delete [SELECT Id FROM reduivy__Job_Queue__c];

// List<reduivy__Individual_Enrollment__c> ienList = [
//     SELECT Id FROM reduivy__Individual_Enrollment__c
//     WHERE RecordTypeId =: IEN_Helper.getStudentRecordTypeId()
//     LIMIT 10
// ];

// Map<Id, reduivy__Individual_Enrollment__c> ienMap = new Map<Id, reduivy__Individual_Enrollment__c>(ienList);

// List<Id> recordIds = new List<Id>(ienMap.keySet());

// Map<String, Object> params = new Map<String, Object>();
// params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_ID, 'a0c9n000001M8BWAA0');
// params.put(JQH_JobQueue_OBJ.PARAM_SOURCE_RECORD_NAME, 'BUS101_CYT1_SYDNEY');
// params.put('enrollmentStatus', 'Enrolled');

// JQH_JobQueue_OBJ job = JQH_JobManager.initNewJob('Sample_Job', recordIds, params);
// JQH_JobManager.queueJob(job, true);


List<reduivy__Study_Offering__c> sofList = [
    SELECT Id FROM reduivy__Study_Offering__c
    WHERE Id = 'a0dAD0000044nw9YAA' OR Id = 'a0dAD0000044nwAYAQ'
];

Map<Id, reduivy__Study_Offering__c> sofMap = new Map<Id, reduivy__Study_Offering__c>(sofList);
List<Id> recordIds = new List<Id>(sofMap.keySet());
Map<String, Object> params = new Map<String, Object>();
params.put('jobOperationContext', 'termRecordId');

JQH_JobManager.executeJobGenerator('Sample_Job', recordIds, params, true);