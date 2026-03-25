/**
 * @author      WDCi (Lean)
 * @date        Sept 2023
 * @group       Test
 * @description Test class for REDU_PostInstallation
 * @changehistory
 * 
 */
@isTest
public inherited sharing class REDU_PostInstallation_TEST {

 
	@IsTest
    static void testInstallScript(){
        
        Test.startTest();
        REDU_PostInstallation pi = new REDU_PostInstallation();
        Test.testInstall(pi, null);

        Id expectedStudentProfileId;
        Id expectedFacultyProfileId;
        Set<Id> expectedStudentPermSet = new Set<Id>();
        Set<Id> expectedFacultyPermSet = new Set<Id>();
        Id expectedCustomNotificationTypeId;

        for (Profile profile : [SELECT Id, Name FROM Profile WHERE Name IN ('REDU - Student', 'REDU - Faculty') WITH SYSTEM_MODE]) {
            if (profile.Name == 'REDU - Student') {
                expectedStudentProfileId = profile.Id;
            } else {
                expectedFacultyProfileId = profile.Id;
            }
        }

        for (PermissionSet permSet : [SELECT Id, Name FROM PermissionSet WHERE Name IN ('REDU_Student', 'REDU_Faculty', 'REDU_Student_Unmanaged', 'REDU_Faculty_Unmanaged') WITH SYSTEM_MODE]) {
            if (permSet.Name == 'REDU_Student' || permSet.Name == 'REDU_Student_Unmanaged') {
                expectedStudentPermSet.add(permSet.Id);
            } else {
                expectedFacultyPermSet.add(permSet.Id);
            }
        }

        for(CustomNotificationType notificationType : [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName='RIO_App_Notification' WITH SYSTEM_MODE]) {
            expectedCustomNotificationTypeId = notificationType.Id;
        }

        //assert custom setting
        System.Assert.areEqual(true, REDU_AppSetting_UTIL.isRioEducationEnabled());
        System.Assert.areEqual(true, String.isNotBlank(REDU_AppSetting_UTIL.getAdministrativeAccountNameFormat()));
        System.Assert.areEqual(expectedStudentProfileId, REDU_AppSetting_UTIL.getStudentProfileId());
        System.Assert.areEqual(expectedFacultyProfileId, REDU_AppSetting_UTIL.getFacultyProfileId());
        System.Assert.areEqual(true, expectedStudentPermSet.containsAll(REDU_AppSetting_UTIL.getStudentPermissionSetIds()));
        System.Assert.areEqual(true, expectedFacultyPermSet.containsAll(REDU_AppSetting_UTIL.getFacultyPermissionSetIds()));
        System.Assert.areEqual(expectedCustomNotificationTypeId, REDU_AppSetting_UTIL.getNotificationTypeId());

        //asert system vars
        Set<String> varsNames = new Set<String>{'STUDENT_ID_COUNTER'};
        List<reduivy__System_Variable__c> existingSysVars = [SELECT Id FROM reduivy__System_Variable__c WHERE Name IN: varsNames WITH USER_MODE];

        System.Assert.isTrue(!existingSysVars.isEmpty(), 'The STUDENT_ID_COUNTER system variable is not found.');

        Test.stopTest();
        
    }
}