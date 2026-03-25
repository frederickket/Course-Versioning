/**
 * @author      WDCi (XiRouh)
 * @date        Nov 2025
 * @group       Trigger Executable
 * @description This is to link a newly create individual enrollment to a individual academic profile.
 * @changehistory
 * ISS-002743 XiRouh 18-11-2025 - New Class
 */
public inherited sharing class IEN_AcademicProfile_EXE extends REDU_TriggerExecutable {

    /**
     * @description Individual enrollment student record type
     */
    private static final Id IEN_STUDENT_RTID = IEN_Helper.getStudentRecordTypeId();

    /**
     * @description Individual enrollment type
     */
    private static final String IEN_ENROLLMENTTYPE_PROGRAM = IEN_Helper.ENROLLMENT_TYPE_PROGRAM;

    /**
     * @description Individual Program Enrollment - in progress statuses
     */
    private static final List<String> IPE_IN_PROGRESS_STATUSES = IPE_Helper.getInProgressStatuses();

    /**
     * @description Individual Program Enrollment - in progress statuses
     */
    private static final Id SPS_UNIT_RTID = SPS_Helper.getUnitRecordTypeId();
    
	/**
     * @description BeforeInsert
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeInsert(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {
        
        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {
            
            List<reduivy__Individual_Enrollment__c> workingIenList = new List<reduivy__Individual_Enrollment__c>();

            for (reduivy__Individual_Enrollment__c ien : (List<reduivy__Individual_Enrollment__c>) newList) {
                if (ien.RecordTypeId == IEN_STUDENT_RTID &&
                    ien.reduivy__Enrollment_Type__c == IEN_ENROLLMENTTYPE_PROGRAM &&
                    String.isNotBlank(ien.reduivy__Contact__c) &&
                    String.isBlank(ien.reduivy__Individual_Academic_Profile__c) &&
                    String.isNotBlank(ien.reduivy__Target_Unit_Id__c)
                ) {
                    workingIenList.add(ien);
                }
            }

            if (!workingIenList.isEmpty()) {
                setAcademicProfile(workingIenList);
            }
        }
    }

    /**
     * @description BeforeUpdate
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeUpdate(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {
        
        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {
            
            List<reduivy__Individual_Enrollment__c> workingIenList = new List<reduivy__Individual_Enrollment__c>();

            for (reduivy__Individual_Enrollment__c ien : (List<reduivy__Individual_Enrollment__c>) newList) {
                reduivy__Individual_Enrollment__c oldIen = (reduivy__Individual_Enrollment__c) oldMap.get(ien.Id);

                if (
                    ien.RecordTypeId == IEN_STUDENT_RTID &&
                    ien.reduivy__Enrollment_Type__c == IEN_ENROLLMENTTYPE_PROGRAM &&
                    String.isNotBlank(ien.reduivy__Contact__c) &&
                    String.isBlank(ien.reduivy__Individual_Academic_Profile__c) &&
                    String.isNotBlank(ien.reduivy__Target_Unit_Id__c) &&
                    (
                        ien.reduivy__Contact__c != oldIen.reduivy__Contact__c ||
                        ien.reduivy__Study_Offering__c != oldIen.reduivy__Study_Offering__c ||
                        ien.reduivy__Individual_Academic_Profile__c != oldien.reduivy__Individual_Academic_Profile__c
                    )
                ) {
                    workingIenList.add(ien);
                }
            }

            if (!workingIenList.isEmpty()) {
                setAcademicProfile(workingIenList);
            }
        }
    }

    /**
     * @description Set the individual enrollment with individual academic profile
     * @param ienList list of individual enrollment
     * @return void
     */
    private void setAcademicProfile(List<reduivy__Individual_Enrollment__c> ienList) {

        Set<Id> contactIds = new Set<Id>();
        Set<Id> studyUnitIds = new Set<Id>();

        for(reduivy__Individual_Enrollment__c ien : ienList) {

            if(String.isNotBlank(ien.reduivy__Contact__c)) {
                contactIds.add(ien.reduivy__Contact__c);
            }

            if(String.isNotBlank(ien.reduivy__Target_Unit_Id__c)) {
                studyUnitIds.add(ien.reduivy__Target_Unit_Id__c);
            }
        }
        
        //Query all IPEs for the contacts
        Map<Id, List<reduivy__Individual_Program_Enrollment__c>> contactToIpeMap = new Map<Id, List<reduivy__Individual_Program_Enrollment__c>>();
        Set<Id> studyPlanIds = new Set<Id>();

        for(reduivy__Individual_Program_Enrollment__c ipe : [
            SELECT Id, 
            reduivy__Contact__c,
            reduivy__Individual_Academic_Profile__c, 
            reduivy__Study_Plan__c,
            reduivy__Master_Enrollment__c,
            reduivy__Master_Enrollment__r.reduivy__Individual_Academic_Profile__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE reduivy__Contact__c IN :contactIds
            AND reduivy__Enrollment_Status__c IN :IPE_IN_PROGRESS_STATUSES
            WITH USER_MODE
        ]) {
            Id ipfId = IPE_Helper.getIpfId(ipe);

            if (String.isNotBlank(ipfId) && String.isNotBlank(ipe.reduivy__Study_Plan__c)) { 
                if (!contactToIpeMap.containsKey(ipe.reduivy__Contact__c)) {
                    contactToIpeMap.put(
                        ipe.reduivy__Contact__c, 
                        new List<reduivy__Individual_Program_Enrollment__c>()
                    );
                }

                contactToIpeMap.get(ipe.reduivy__Contact__c).add(ipe);
                studyPlanIds.add(ipe.reduivy__Study_Plan__c);
            }
        }

        //Query Study Plan Structures to find which study plans contain which study units
        Map<Id, Set<Id>> studyPlanToUnitsMap = new Map<Id, Set<Id>>();
        
        for(reduivy__Study_Plan_Structure__c sps : [
            SELECT Id,
            reduivy__Study_Plan__c,
            reduivy__Study_Unit__c
            FROM reduivy__Study_Plan_Structure__c
            WHERE reduivy__Study_Plan__c IN :studyPlanIds
            AND reduivy__Study_Unit__c IN :studyUnitIds
            AND RecordTypeId = :SPS_UNIT_RTID
            WITH USER_MODE
        ]) {
            if (!studyPlanToUnitsMap.containsKey(sps.reduivy__Study_Plan__c)) {
                studyPlanToUnitsMap.put(sps.reduivy__Study_Plan__c, new Set<Id>());
            }

            studyPlanToUnitsMap.get(sps.reduivy__Study_Plan__c).add(sps.reduivy__Study_Unit__c);
        }

        //Process each IEN to find matching IPF
        for(reduivy__Individual_Enrollment__c ien : ienList) {
            List<reduivy__Individual_Program_Enrollment__c> contactIpes = contactToIpeMap.get(ien.reduivy__Contact__c);
            
            if (contactIpes == null || contactIpes.isEmpty()) {
                String errorMsg = String.format(Label.No_Active_Record_Found, new List<String>{IPE_Helper.getObjectLabel(), IPF_Helper.getObjectLabel()});

                ien.addError(errorMsg);
                continue;
            }

            Set<Id> matchingIpfIds = new Set<Id>();

            //Find all IPFs that have IPEs with study plans containing the target unit
            for(reduivy__Individual_Program_Enrollment__c ipe : contactIpes) {
                Set<Id> unitsInStudyPlan = studyPlanToUnitsMap.get(ipe.reduivy__Study_Plan__c);
                
                if (unitsInStudyPlan != null && unitsInStudyPlan.contains(ien.reduivy__Target_Unit_Id__c)) {
                    Id academicProfileId = IPE_Helper.getIpfId(ipe);

                    matchingIpfIds.add(academicProfileId);
                }
            }

            if (matchingIpfIds.isEmpty()) {
                String errorMsg = String.format(Label.No_Matching_Record_Found, new List<String>{IPF_Helper.getObjectLabel()});

                ien.addError(errorMsg);
            } else if (matchingIpfIds.size() > 1) {
                String errorMsg = String.format(Label.Multiple_Matching_Record_Found, new List<String>{IPF_Helper.getObjectLabel()});
                
                ien.addError(errorMsg);
            } else {
                ien.reduivy__Individual_Academic_Profile__c = new List<Id>(matchingIpfIds)[0];
            }
        }
    }
}