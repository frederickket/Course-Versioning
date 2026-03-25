/**
 * @author      WDCi (Lean)
 * @date        July 2023
 * @group       Installation
 * @description Post installation script
 * @changehistory
 * ISS-002784 28-01-2026 Lean - Make exclude gpa enabled by default
 */
global without sharing class REDU_PostInstallation implements InstallHandler {
    
    /**
     * @description Specifies the actions to be performed on install/upgrade.
     * @return void
     */
    global void onInstall(InstallContext context){

        try {
            Database.upsert(createAppSetting(context), AccessLevel.SYSTEM_MODE);
            performUpgradeTasks(context);

        } catch (Exception exp) {

            //email post installation script error to current user
            Map<String, Object> userBindParams = new Map<String, Object>();
            userBindParams.put('installerId', context.installerID());

            String userSoql = 'SELECT Id, Email FROM User WHERE Id =: installerId';
            List<User> users = (List<User>) Database.queryWithBinds(userSoql, userBindParams, AccessLevel.SYSTEM_MODE);
            
            User u = users.get(0); 
            String toAddress= u.Email;
            String[] toAddresses = new String[]{toAddress};
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

            mail.setToAddresses(toAddresses);
            mail.setReplyTo('support@wdcigroup.net');
            mail.setSenderDisplayName('WDCi Support');
            mail.setSubject('RIO Education V4: Post installation script error');

            String errorBody = 'Unfortunately, the RIO Education V4 post installation script failed. Please forward the following error to support@wdcigroup.net for further assistance.';
            errorBody += '\nError message: ' + exp.getMessage();
            errorBody += '\nLine number: ' + exp.getLineNumber();
            errorBody += '\nStacktrace: ' + exp.getStackTraceString();

            mail.setPlainTextBody(errorBody);
            
            Messaging.sendEmail(new Messaging.Email[] { mail });
        }
    }

    /**
    * @description Init app settings
    * @return reduivy__RIO_Education_Ivy_Settings__c
    */
    private reduivy__RIO_Education_Ivy_Settings__c createAppSetting(InstallContext context){
    
        reduivy__RIO_Education_Ivy_Settings__c appSetting = reduivy__RIO_Education_Ivy_Settings__c.getOrgDefaults();

        //Fresh install
        if (context.previousVersion() == null){
            appSetting = initAppSetting(appSetting);
            
        //Upgrade
        } else if(context.isUpgrade()){
            if (context.previousVersion().compareTo(new Version(0, 2, 0)) < 0) {
                
                appSetting.reduivy__Default_Owner_Id__c = context.installerId();

            } else if (context.previousVersion().compareTo(new Version(1, 0, 0)) < 0) {
                
                for(CustomNotificationType notificationType : [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName='RIO_App_Notification' WITH SYSTEM_MODE]) {
                    appSetting.reduivy__Notification_Type_Id__c = notificationType.Id;
                }

            } else if (context.previousVersion().compareTo(new Version(1, 1, 0)) < 0) {
                //v4.0
                appSetting.Enable_RIO_Education__c = true;

            }
        }

        return appSetting;
    }

    /**
     * @description Default app settings
     * @param appSetting
     * @return reduivy__RIO_Education_Ivy_Settings__c
     */
    global reduivy__RIO_Education_Ivy_Settings__c initAppSetting(reduivy__RIO_Education_Ivy_Settings__c appSetting){

        if (appSetting == null) {
            appSetting = reduivy__RIO_Education_Ivy_Settings__c.getOrgDefaults();
        }

        for (Profile profile : [SELECT Id, Name FROM Profile WHERE Name IN ('REDU - Student', 'REDU - Faculty') WITH SYSTEM_MODE]) {
            if (profile.Name == 'REDU - Student') {
                appSetting.reduivy__Student_Profile_Id__c = profile.Id;
            } else {
                appSetting.reduivy__Faculty_Profile_Id__c = profile.Id;
            }
        }

        Set<Id> studentPermSet = new Set<Id>();
        Set<Id> facultyPermSet = new Set<Id>();
        for (PermissionSet permSet : [SELECT Id, Name FROM PermissionSet WHERE Name IN ('REDU_Student', 'REDU_Faculty', 'REDU_Student_Unmanaged', 'REDU_Faculty_Unmanaged') WITH SYSTEM_MODE]) {
            if (permSet.Name == 'REDU_Student' || permSet.Name == 'REDU_Student_Unmanaged') {
                studentPermSet.add(permSet.Id);
            } else {
                facultyPermSet.add(permSet.Id);
            }
        }
        if(!studentPermSet.isEmpty()) {
            appSetting.reduivy__Student_Permission_Set_Ids__c = String.join(studentPermSet, REDU_List_UTIL.DELIMITER);
        }
        if(!facultyPermSet.isEmpty()){
            appSetting.reduivy__Faculty_Permission_Set_Ids__c = String.join(facultyPermSet, REDU_List_UTIL.DELIMITER);
        }

        for(CustomNotificationType notificationType : [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName='RIO_App_Notification' WITH SYSTEM_MODE]) {
            appSetting.reduivy__Notification_Type_Id__c = notificationType.Id;
        }

        appSetting.reduivy__Enable_RIO_Education__c = true;
        
        //ISS-002784
        appSetting.Exclude_GPA_For_Repeated_Unit__c = true;

        return appSetting;
    }

    public void performUpgradeTasks(InstallContext context) {

        //Fresh install
        if (context.previousVersion() == null){
            doV41UpgradeTask();
            doV42UpgradeTask();
            
        //Upgrade
        } else if(context.isUpgrade()){
            if (context.previousVersion().compareTo(new Version(1, 4, 0)) < 0) {
                //v4.1
                doV41UpgradeTask();

            } else if (context.previousVersion().compareTo(new Version(4, 2, 0)) < 0) {
                //v4.2
                doV42UpgradeTask();
            }
        }
    }

    public void doV41UpgradeTask() {
        List<Account> eduInstAndCampuses = [SELECT Id, reduivy__Status__c FROM Account WHERE RecordTypeId =: ACC_Helper.getCampusRecordTypeId() OR RecordTypeId =: ACC_Helper.getEducationalInstitutionRecordTypeId() WITH SYSTEM_MODE];
        for (Account acc : eduInstAndCampuses) {
            acc.reduivy__Status__c = 'Active';
        }

        List<reduivy__Study_Cohort_Enrollment__c> sceList = [SELECT Id, reduivy__Status__c FROM reduivy__Study_Cohort_Enrollment__c WHERE reduivy__Status__c = NULL WITH SYSTEM_MODE];
        for (reduivy__Study_Cohort_Enrollment__c sce : sceList) {
            sce.reduivy__Status__c = 'Active';
        }

        List<reduivy__Study_Grade_Period_Setting__c> sgpList = [SELECT Id, reduivy__Status__c FROM reduivy__Study_Grade_Period_Setting__c WHERE reduivy__Status__c = NULL WITH SYSTEM_MODE];
        for (reduivy__Study_Grade_Period_Setting__c sgp : sgpList) {
            sgp.reduivy__Status__c = 'Active';
        }

        List<reduivy__Study_Grade_Setting__c> sgsList = [SELECT Id, reduivy__Status__c FROM reduivy__Study_Grade_Setting__c WHERE reduivy__Status__c = NULL WITH SYSTEM_MODE];
        for (reduivy__Study_Grade_Setting__c sgs : sgsList) {
            sgs.reduivy__Status__c = 'Active';
        }

        List<reduivy__Study_Term__c> stmList = [SELECT Id, reduivy__Status__c FROM reduivy__Study_Term__c WHERE RecordTypeId =: STM_Helper.getAcademicTermRecordTypeId() WITH SYSTEM_MODE];
        for (reduivy__Study_Term__c stm : stmList) {
            stm.reduivy__Status__c = 'Active';
        }

        REDU_TriggerController.muteAllTriggers();

        if (!eduInstAndCampuses.isEmpty()) {
            REDU_SystemMode_UTIL.doUpdate(eduInstAndCampuses);
        }

        if (!sceList.isEmpty()) {
            REDU_SystemMode_UTIL.doUpdate(sceList);
        }

        if (!sgpList.isEmpty()) {
            REDU_SystemMode_UTIL.doUpdate(sgpList);
        }

        if (!sgsList.isEmpty()) {
            REDU_SystemMode_UTIL.doUpdate(sgsList);
        }

        if (!stmList.isEmpty()) {
            REDU_SystemMode_UTIL.doUpdate(stmList);
        }

        REDU_TriggerController.unmuteAllTriggers();
    }

    public void doV42UpgradeTask() {

        Set<String> varsNames = new Set<String>{'STUDENT_ID_COUNTER'};
        List<reduivy__System_Variable__c> existingSysVars = [SELECT Id FROM reduivy__System_Variable__c WHERE Name IN: varsNames WITH SYSTEM_MODE];

        //create sys var if missing
        if (existingSysVars.isEmpty()) {
            reduivy__System_Variable__c studentIdSyv = new reduivy__System_Variable__c();
            studentIdSyv.reduivy__Number__c = 0;
            studentIdSyv.reduivy__Format__c = 'STUD-{000000}';
            studentIdSyv.Name = 'STUDENT_ID_COUNTER';

            REDU_TriggerController.muteAllTriggers();

            REDU_SystemMode_UTIL.doInsert(new List<reduivy__System_Variable__c>{studentIdSyv});

            REDU_TriggerController.unmuteAllTriggers();
        }
    }
}