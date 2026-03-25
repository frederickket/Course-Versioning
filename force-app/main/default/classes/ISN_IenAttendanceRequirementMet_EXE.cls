/**
 * @author      WDCi (VTan)
 * @date        Aug 2024
 * @group       Trigger Executable
 * @description Update attendance requirement met at the related IEN
 * @changehistory
 * ISS-002055 29-08-2024 VTan - new class
 */
public inherited sharing class ISN_IenAttendanceRequirementMet_EXE extends REDU_TriggerExecutable {

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

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN) ||
            REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.FACULTY)
        ) {

            Map<Id, List<reduivy__Individual_Session_Enrollment__c>> ienIsnListMap = new Map<Id, List<reduivy__Individual_Session_Enrollment__c>>();
            Id isnStudentRtId = ISN_Helper.getStudentRecordTypeId();
            for (reduivy__Individual_Session_Enrollment__c isnNew : (List<reduivy__Individual_Session_Enrollment__c>) newList) {

                //Only consider individual session enrollment for student, positive status
                if (isnNew.RecordTypeId == isnStudentRtId && String.isNotBlank(isnNew.reduivy__Individual_Enrollment__c) && String.isNotBlank(isnNew.reduivy__Study_Session__c) &&
                    (ISN_Helper.getInProgressStatuses().contains(isnNew.reduivy__Enrollment_Status__c) || ISN_Helper.getCompletedStatuses().contains(isnNew.reduivy__Enrollment_Status__c))) {

                    if(ienIsnListMap.containsKey(isnNew.reduivy__Individual_Enrollment__c)){
                        ienIsnListMap.get(isnNew.reduivy__Individual_Enrollment__c).add(isnNew);
                    }else{
                        ienIsnListMap.put(isnNew.reduivy__Individual_Enrollment__c, new List<reduivy__Individual_Session_Enrollment__c>{isnNew});
                    }
                }
            }

            if(!ienIsnListMap.isEmpty()){
                updateIenAttendanceRequirementMet(ienIsnListMap);
            }
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
        
        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN) ||
            REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.FACULTY)
        ) {

            Map<Id, List<reduivy__Individual_Session_Enrollment__c>> ienIsnListMap = new Map<Id, List<reduivy__Individual_Session_Enrollment__c>>();
            Id isnStudentRtId = ISN_Helper.getStudentRecordTypeId();
            for (reduivy__Individual_Session_Enrollment__c isnNew : (List<reduivy__Individual_Session_Enrollment__c>) newList) {

                reduivy__Individual_Session_Enrollment__c ienOld = (reduivy__Individual_Session_Enrollment__c) oldMap.get(isnNew.Id);
                //Only consider individual session enrollment for student, status changed, attendance percentage changed, individual enrollment changed
                if (isnNew.RecordTypeId == isnStudentRtId && String.isNotBlank(isnNew.reduivy__Individual_Enrollment__c) && String.isNotBlank(isnNew.reduivy__Study_Session__c) &&
                    (isnNew.reduivy__Enrollment_Status__c != ienOld.reduivy__Enrollment_Status__c || isnNew.reduivy__Attendance_Percentage__c != ienOld.reduivy__Attendance_Percentage__c)) {

                    if(ienIsnListMap.containsKey(isnNew.reduivy__Individual_Enrollment__c)){
                        ienIsnListMap.get(isnNew.reduivy__Individual_Enrollment__c).add(isnNew);
                    }else{
                        ienIsnListMap.put(isnNew.reduivy__Individual_Enrollment__c, new List<reduivy__Individual_Session_Enrollment__c>{isnNew});
                    }

                    // Handle individual enrollment changed
                    if(isnNew.reduivy__Individual_Enrollment__c != ienOld.reduivy__Individual_Enrollment__c){
                        
                        if(ienIsnListMap.containsKey(ienOld.reduivy__Individual_Enrollment__c)){
                            ienIsnListMap.get(ienOld.reduivy__Individual_Enrollment__c).add(isnNew);
                        }else{
                            ienIsnListMap.put(ienOld.reduivy__Individual_Enrollment__c, new List<reduivy__Individual_Session_Enrollment__c>{isnNew});
                        }
                    }
                }
            }

            if(!ienIsnListMap.isEmpty()){
                updateIenAttendanceRequirementMet(ienIsnListMap);
            }
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

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN) ||
            REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.FACULTY)
        ) {

            Map<Id, List<reduivy__Individual_Session_Enrollment__c>> ienIsnListMap = new Map<Id, List<reduivy__Individual_Session_Enrollment__c>>();
            Id isnStudentRtId = ISN_Helper.getStudentRecordTypeId();
            for (reduivy__Individual_Session_Enrollment__c isnOld : (List<reduivy__Individual_Session_Enrollment__c>) oldList) {
                
                //Only consider individual session enrollment for student, positive status
                if (isnOld.RecordTypeId == isnStudentRtId && String.isNotBlank(isnOld.reduivy__Individual_Enrollment__c) && String.isNotBlank(isnOld.reduivy__Study_Session__c) &&
                    (ISN_Helper.getInProgressStatuses().contains(isnOld.reduivy__Enrollment_Status__c) || ISN_Helper.getCompletedStatuses().contains(isnOld.reduivy__Enrollment_Status__c))) {

                    if(ienIsnListMap.containsKey(isnOld.reduivy__Individual_Enrollment__c)){
                        ienIsnListMap.get(isnOld.reduivy__Individual_Enrollment__c).add(isnOld);
                    }else{
                        ienIsnListMap.put(isnOld.reduivy__Individual_Enrollment__c, new List<reduivy__Individual_Session_Enrollment__c>{isnOld});
                    }
                }
            }

            if(!ienIsnListMap.isEmpty()){
                updateIenAttendanceRequirementMet(ienIsnListMap);
            }
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

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN) ||
            REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.FACULTY)
        ) {

            Map<Id, List<reduivy__Individual_Session_Enrollment__c>> ienIsnListMap = new Map<Id, List<reduivy__Individual_Session_Enrollment__c>>();
            Id isnStudentRtId = ISN_Helper.getStudentRecordTypeId();
            for (reduivy__Individual_Session_Enrollment__c isnNew : (List<reduivy__Individual_Session_Enrollment__c>) newList) {

                //Only consider individual session enrollment for student, positive status
                if (isnNew.RecordTypeId == isnStudentRtId && String.isNotBlank(isnNew.reduivy__Individual_Enrollment__c) && String.isNotBlank(isnNew.reduivy__Study_Session__c) &&
                    (ISN_Helper.getInProgressStatuses().contains(isnNew.reduivy__Enrollment_Status__c) || ISN_Helper.getCompletedStatuses().contains(isnNew.reduivy__Enrollment_Status__c))) {

                    if(ienIsnListMap.containsKey(isnNew.reduivy__Individual_Enrollment__c)){
                        ienIsnListMap.get(isnNew.reduivy__Individual_Enrollment__c).add(isnNew);
                    }else{
                        ienIsnListMap.put(isnNew.reduivy__Individual_Enrollment__c, new List<reduivy__Individual_Session_Enrollment__c>{isnNew});
                    }
                }
            }

            if(!ienIsnListMap.isEmpty()){
                updateIenAttendanceRequirementMet(ienIsnListMap);
            }
        }
    }

    /**
     * @description update Attendance requirement met = yes/no according to the individual session enrollment and study session's required attendance % 
     * @param ienIds New individual enrollment
     * @return void
     */
    private void updateIenAttendanceRequirementMet(Map<Id, List<reduivy__Individual_Session_Enrollment__c>> ienIsnListMap) {

        // Get related individual session enrollment for attendance check
        Set<String> isnStatuses = new Set<String>();
        isnStatuses.addAll(ISN_Helper.getInProgressStatuses());
        isnStatuses.addAll(ISN_Helper.getCompletedStatuses());

        String ienQuery = 'SELECT Id, reduivy__Attendance_Requirement_Met__c, ' +
        ' (SELECT Id, reduivy__Attendance_Percentage__c, reduivy__Study_Session__r.reduivy__Required_Attendance_Percentage__c'+
        ' FROM reduivy__Individual_Session_Enrollments__r' +
        ' WHERE recordTypeId = : isnStudentRtId' +
        ' AND reduivy__Study_Session__r.reduivy__Required_Attendance_Percentage__c > 0' +
        ' AND reduivy__Enrollment_Status__c IN : isnStatuses)' +
        ' FROM reduivy__Individual_Enrollment__c' +
        ' WHERE Id IN : ienIds';

        Map<String, Object> ienBindParams = new Map<String, Object>{
            'ienIds' => ienIsnListMap.keySet(),
            'isnStatuses' => isnStatuses,
            'isnStudentRtId' => ISN_Helper.getStudentRecordTypeId()
        };

        List<reduivy__Individual_Enrollment__c> updateIenList = new List<reduivy__Individual_Enrollment__c>();
        for(reduivy__Individual_Enrollment__c ien : (List<reduivy__Individual_Enrollment__c>) Database.queryWithBinds(ienQuery, ienBindParams, AccessLevel.USER_MODE)){

            String attRequirementMet = IEN_Helper.ATTENDANCE_REQUIREMENT_MET_YES;
            for(reduivy__Individual_Session_Enrollment__c isn : ien.reduivy__Individual_Session_Enrollments__r){

                if(isn.reduivy__Attendance_Percentage__c < isn.reduivy__Study_Session__r.reduivy__Required_Attendance_Percentage__c){
                    attRequirementMet = IEN_Helper.ATTENDANCE_REQUIREMENT_MET_NO;
                    break;
                }
            }

            if(ien.reduivy__Attendance_Requirement_Met__c != attRequirementMet){
                updateIenList.add(new reduivy__Individual_Enrollment__c(Id = ien.Id, reduivy__Attendance_Requirement_Met__c = attRequirementMet));
            }
        }

        if(!updateIenList.isEmpty()){
            REDU_Database_UTIL.doUpdate(updateIenList, ienIsnListMap, 'Id', false);
        }
    }
}