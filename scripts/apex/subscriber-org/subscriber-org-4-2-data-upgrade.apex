reduivy__System_Variable__c studentIdSyv = new reduivy__System_Variable__c();
studentIdSyv.reduivy__Number__c = 0;
studentIdSyv.reduivy__Format__c = 'STUD-{000000}';
studentIdSyv.Name = 'STUDENT_ID_COUNTER';

reduivy.REDU_TriggerController.muteAllTriggers();

insert studentIdSyv;

reduivy.REDU_TriggerController.unmuteAllTriggers();