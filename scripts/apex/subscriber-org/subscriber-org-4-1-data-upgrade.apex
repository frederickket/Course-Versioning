List<Account> eduInstAndCampuses = [SELECT Id, reduivy__Status__c FROM Account WHERE RecordTypeId =: reduivy.ACC_Helper.getCampusRecordTypeId() OR RecordTypeId =: reduivy.ACC_Helper.getEducationalInstitutionRecordTypeId()];
for (Account acc : eduInstAndCampuses) {
    acc.reduivy__Status__c = 'Active';
}

List<reduivy__Study_Cohort_Enrollment__c> sceList = [SELECT Id, reduivy__Status__c FROM reduivy__Study_Cohort_Enrollment__c];
for (reduivy__Study_Cohort_Enrollment__c sce : sceList) {
    sce.reduivy__Status__c = 'Active';
}

List<reduivy__Study_Grade_Period_Setting__c> sgpList = [SELECT Id, reduivy__Status__c FROM reduivy__Study_Grade_Period_Setting__c];
for (reduivy__Study_Grade_Period_Setting__c sgp : sgpList) {
    sgp.reduivy__Status__c = 'Active';
}

List<reduivy__Study_Grade_Setting__c> sgsList = [SELECT Id, reduivy__Status__c FROM reduivy__Study_Grade_Setting__c];
for (reduivy__Study_Grade_Setting__c sgs : sgsList) {
    sgs.reduivy__Status__c = 'Active';
}

List<reduivy__Study_Term__c> stmList = [SELECT Id, reduivy__Status__c FROM reduivy__Study_Term__c WHERE RecordTypeId =: reduivy.STM_Helper.getAcademicTermRecordTypeId()];
for (reduivy__Study_Term__c stm : stmList) {
    stm.reduivy__Status__c = 'Active';
}

reduivy.REDU_TriggerController.muteAllTriggers();

update eduInstAndCampuses;
update sceList;
update sgpList;
update sgsList;
update stmList;

reduivy.REDU_TriggerController.unmuteAllTriggers();