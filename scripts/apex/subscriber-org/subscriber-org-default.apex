//we invoke the post installation instead of data factory to avoid the role and scratch org settings
reduivy.REDU_PostInstallation pi = new reduivy.REDU_PostInstallation();
reduivy__RIO_Education_Ivy_Settings__c settings = pi.initAppSetting(null);

upsert settings;