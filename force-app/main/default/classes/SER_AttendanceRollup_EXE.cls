/**
 * @author      WDCi (Sueanne)
 * @date        Aug 2024
 * @group       Trigger executable
 * @description To do rollup for individual session enrollment when update, insert, delete or undelete the study event relation
 * @changehistory
 * ISS-002049 26-08-2024 Sueanne - new class
 */
public without sharing class SER_AttendanceRollup_EXE extends REDU_TriggerExecutable {
    
    private final static Set<String> ATTENDANCE_MARKED_STATUSES = SER_Helper.getAttendanceMarkedStatuses();
    private final static Set<String> TOTAL_ATTENDED_STATUSES = new Set<String>{SER_Helper.ATTENDANCE_STATUS_ATTENDED, SER_Helper.ATTENDANCE_STATUS_LATE};
    private final static Set<String> TOTAL_ABSENT_STATUSES = new Set<String>{SER_Helper.ATTENDANCE_STATUS_ABSENT};
    private final static Set<String> TOTAL_EXCUSED_STATUSES = new Set<String>{SER_Helper.ATTENDANCE_STATUS_EXCUSED};

    private final static String ISN_STUDENT_RTID = ISN_Helper.getStudentRecordTypeId();
    private final static String RELATION_TYPE_STUDENT = SER_Helper.RELATION_TYPE_STUDENT;

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

            List<reduivy__Study_Event_Relation__c> serList = new List<reduivy__Study_Event_Relation__c>();

            for(reduivy__Study_Event_Relation__c ser : (List<reduivy__Study_Event_Relation__c>) newList){
                if(
                    String.isNotBlank(ser.reduivy__Attendance_Status__c) 
                    && String.isNotBlank(ser.reduivy__Individual_Session_Enrollment__c)
                    && ATTENDANCE_MARKED_STATUSES.contains(ser.reduivy__Attendance_Status__c) 
                    && ser.reduivy__Relation_Type__c == RELATION_TYPE_STUDENT
                ){
                    serList.add(ser);
                }
            }

            if(!serList.isEmpty()){
                doRollup(serList);
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

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            Map<Id, reduivy__Study_Event_Relation__c> oldSerMap = new Map<Id, reduivy__Study_Event_Relation__c>((List<reduivy__Study_Event_Relation__c>) oldList);
            List<reduivy__Study_Event_Relation__c> serList = new List<reduivy__Study_Event_Relation__c>();

            for(reduivy__Study_Event_Relation__c ser : (List<reduivy__Study_Event_Relation__c>) newList){

                reduivy__Study_Event_Relation__c oldSer = oldSerMap.get(ser.Id);

                if(
                    ser.reduivy__Individual_Session_Enrollment__c != oldSer.reduivy__Individual_Session_Enrollment__c
                    || oldSer.reduivy__Attendance_Status__c != ser.reduivy__Attendance_Status__c
                    || ser.reduivy__Relation_Type__c != oldSer.reduivy__Relation_Type__c
                ){
                    if(
                        String.isNotBlank(ser.reduivy__Individual_Session_Enrollment__c)
                        && String.isNotBlank(ser.reduivy__Attendance_Status__c) 
                        && ATTENDANCE_MARKED_STATUSES.contains(ser.reduivy__Attendance_Status__c)
                    ){
                        serList.add(ser);
                    }

                    if(
                        String.isNotBlank(oldSer.reduivy__Individual_Session_Enrollment__c)
                        && ser.reduivy__Individual_Session_Enrollment__c != oldSer.reduivy__Individual_Session_Enrollment__c
                    ){
                        serList.add(oldSer);
                    }
                }
            }
 
            if(!serList.isEmpty()){
                doRollup(serList);
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

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            List<reduivy__Study_Event_Relation__c> serList = new List<reduivy__Study_Event_Relation__c>();

            for(reduivy__Study_Event_Relation__c ser : (List<reduivy__Study_Event_Relation__c>) oldList){

                if(
                    String.isNotBlank(ser.reduivy__Attendance_Status__c) 
                    && String.isNotBlank(ser.reduivy__Individual_Session_Enrollment__c)
                    && ATTENDANCE_MARKED_STATUSES.contains(ser.reduivy__Attendance_Status__c)
                    && ser.reduivy__Relation_Type__c == RELATION_TYPE_STUDENT
                ){
                    serList.add(ser);
                }
            }

            if(!serList.isEmpty()){
                doRollup(serList);
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
        
        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER)) {

            List<reduivy__Study_Event_Relation__c> serList = new List<reduivy__Study_Event_Relation__c>();

            for(reduivy__Study_Event_Relation__c ser : (List<reduivy__Study_Event_Relation__c>) newList){
                
                if(
                    String.isNotBlank(ser.reduivy__Attendance_Status__c) 
                    && String.isNotBlank(ser.reduivy__Individual_Session_Enrollment__c)
                    && ATTENDANCE_MARKED_STATUSES.contains(ser.reduivy__Attendance_Status__c)
                    && ser.reduivy__Relation_Type__c == RELATION_TYPE_STUDENT
                ){
                    serList.add(ser);
                }
            }

            if(!serList.isEmpty()){
                doRollup(serList);
            }
        }
    }


    /**
     * @description This is the method that performs the roll up calculation.
     * @param serList study event relation list to rollup
     */
    private static void doRollup(List<reduivy__Study_Event_Relation__c> serList){

        List<reduivy__Individual_Session_Enrollment__c> isnToUpdate = new List<reduivy__Individual_Session_Enrollment__c>();
        Map<Id, List<reduivy__Study_Event_Relation__c>> parentChildsMap = new Map<Id, List<reduivy__Study_Event_Relation__c>>();

        for(reduivy__Study_Event_Relation__c ser : serList){
            
            if(!parentChildsMap.containsKey(ser.reduivy__Individual_Session_Enrollment__c)){
                parentChildsMap.put(ser.reduivy__Individual_Session_Enrollment__c, new List<reduivy__Study_Event_Relation__c>());
            }
            parentChildsMap.get(ser.reduivy__Individual_Session_Enrollment__c).add(ser);
        }

        for (reduivy__Individual_Session_Enrollment__c isn : [
            SELECT Id, reduivy__Total_Absent__c, reduivy__Total_Attended__c, reduivy__Total_Excused__c,
                (SELECT Id, reduivy__Attendance_Status__c 
                FROM reduivy__Study_Event_Relations__r 
                WHERE reduivy__Relation_Type__c = :RELATION_TYPE_STUDENT 
                AND reduivy__Attendance_Status__c IN: ATTENDANCE_MARKED_STATUSES)
            FROM reduivy__Individual_Session_Enrollment__c
            WHERE Id IN: parentChildsMap.keySet()
            WITH SYSTEM_MODE
            FOR UPDATE
        ]){
            Integer attended = 0;
            Integer absent = 0;
            Integer excused = 0;

            for (reduivy__Study_Event_Relation__c ser : isn.reduivy__Study_Event_Relations__r) {
                if(TOTAL_ATTENDED_STATUSES.contains(ser.reduivy__Attendance_Status__c)){
                    attended++;
    
                } else if(TOTAL_ABSENT_STATUSES.contains(ser.reduivy__Attendance_Status__c)){
                    absent++;
    
                }else if(TOTAL_EXCUSED_STATUSES.contains(ser.reduivy__Attendance_Status__c)){
                    excused++;
                }
            }
            
            if (isn.reduivy__Total_Attended__c != attended || isn.reduivy__Total_Absent__c != absent || isn.reduivy__Total_Excused__c != excused) {

                reduivy__Individual_Session_Enrollment__c isnUpdate = new reduivy__Individual_Session_Enrollment__c();
                isnUpdate.Id = isn.Id;
                isnUpdate.reduivy__Total_Attended__c = attended;
                isnUpdate.reduivy__Total_Absent__c = absent;
                isnUpdate.reduivy__Total_Excused__c = excused;

                isnToUpdate.add(isnUpdate);
            }
        }
        
        //update isn
        if(!isnToUpdate.isEmpty()){
            //Rollup using system mode as the fields are non editable by normal user
            REDU_SystemMode_UTIL.doUpdate(isnToUpdate, parentChildsMap, 'Id', false);
        }

    }
}