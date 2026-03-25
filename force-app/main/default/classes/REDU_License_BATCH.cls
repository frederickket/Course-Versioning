/**
 * @author      WDCi (Lean)
 * @date        Aug 2023
 * @group       License
 * @description Batchable job to calculate license usage
 * @changehistory
 * ISS-001858 19-03-2024 VTan - Introduce logic to exclude applicant user.
 * ISS-002574 04-08-2025 Lean - Decommission the applicant license type count
 */
global without sharing class REDU_License_BATCH  implements Database.Batchable<SObject>, Database.Stateful {
    
    String licenseType;
    Set<Id> permissionSetIds;
    Integer usersCount;

    /**
     * @description Default constructor
     * @param licenseType
     */
    global REDU_License_BATCH(String licenseType) {
        this.usersCount = 0;
        this.licenseType = licenseType;

        String licenseTypeForQuery = licenseType;

        List<CustomPermission> cpList = [SELECT Id, 
            DeveloperName 
            FROM CustomPermission 
            WHERE DeveloperName =: licenseTypeForQuery 
            WITH SYSTEM_MODE
        ];
        
        Set<Id> permissionSetIds = new Set<Id>();
        for (SetupEntityAccess sea : [SELECT 
            SetupEntityId, ParentId 
            FROM SetupEntityAccess 
            WHERE SetupEntityType = 'CustomPermission' 
            AND SetupEntityId IN: cpList
            WITH SYSTEM_MODE
        ]) {
            permissionSetIds.add(sea.ParentId);
        }

        this.permissionSetIds = permissionSetIds;
    }

    /**
     * @description BK_DoubleBooking_BATCH start.
     * @param bc - Database.BatchableContext
     * @return Database.QueryLocator
     */
    global Database.QueryLocator start(Database.BatchableContext bc){
        String queryString = 'SELECT AssigneeId FROM PermissionSetAssignment ' +
            ' WHERE PermissionSetId IN :permissionSetIds ' +
            ' AND Assignee.IsActive = TRUE ' +
            ' WITH SYSTEM_MODE ';
        
        return Database.getQueryLocator(
            queryString
        );
    }

    /**
     * @description BK_DoubleBooking_BATCH execute.
     * @param bc - Database.BatchableContext
     * @param scope - List<rio_ed__Allocation__c>
     * @return void
     */
    global void execute(Database.BatchableContext bc, List<PermissionSetAssignment> scope){

        Set<Id> userIds = new Set<Id>();
        for (PermissionSetAssignment psa : scope) {

            userIds.add(psa.AssigneeId);
        }

        this.usersCount += userIds.size();
    }

    /**
     * @description BK_DoubleBooking_BATCH finish
     * @param bc - Database.BatchableContext
     * @return void
     */
    global void finish(Database.BatchableContext bc){

        if (licenseType == REDU_LicenseManagement_UTIL.ADMIN) {
            REDU_LicenseManagement_UTIL.setAdminUsedLicense(usersCount);
        } else if (licenseType == REDU_LicenseManagement_UTIL.FACULTY) {
            REDU_LicenseManagement_UTIL.setFacultyUsedLicense(usersCount);
        } else if (licenseType == REDU_LicenseManagement_UTIL.STUDENT) {
            REDU_LicenseManagement_UTIL.setStudentUsedLicense(usersCount);
        }
    }
}