/**
 * @author      WDCi (Jordan)
 * @date        Nov 2024
 * @group       Trigger executable
 * @description Update contact type to Alumni when an student completes a program.
 * @changehistory
 * ISS-002088 08-11-202 Jordan - new class
 */
public inherited sharing class IPE_SetContactAlumni_EXE extends REDU_TriggerExecutable {

    /**
     * @description IPE in progress status list
     */
    private static final List<String> IPESTATUS_INPROGRESS = IPE_Helper.getInProgressStatuses();
    
    /**
     * @description IPE completed status list
     */
    private static final List<String> IPESTATUS_COMPLETED = IPE_Helper.getCompletedStatuses();
    
    /**
     * @description IPE Master record type id
     */
    private static final Id IPE_RTID_MASTER = IPE_Helper.getMasterEnrollmentRecordTypeId();

    /**
     * @description Contact Alumni type
     */
    private static final String CONTACT_TYPE_ALUMNI = CON_Helper.CONTACT_TYPE_ALUMNI;

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

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN)) {

            Set<Id> qualifiedContactIdSet = new Set<Id>();
            
            for (reduivy__Individual_Program_Enrollment__c ipeNew : (List<reduivy__Individual_Program_Enrollment__c>) newList) {    
                if (String.isNotBlank(ipeNew.reduivy__Contact__c) && 
                    IPESTATUS_COMPLETED.contains(ipeNew.reduivy__Enrollment_Status__c) && 
                    ipeNew.RecordTypeId == IPE_RTID_MASTER
                ) {
                    qualifiedContactIdSet.add(ipeNew.reduivy__Contact__c);
                }
            }

            if(!qualifiedContactIdSet.isEmpty()){
                setContactAlumni(qualifiedContactIdSet);
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

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN)) {

            Map<Id, reduivy__Individual_Program_Enrollment__c> ipeOldMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>((List<reduivy__Individual_Program_Enrollment__c>) oldList);

            Set<Id> qualifiedContactIdSet = new Set<Id>();
            
            for (reduivy__Individual_Program_Enrollment__c ipeNew : (List<reduivy__Individual_Program_Enrollment__c>) newList) {
                reduivy__Individual_Program_Enrollment__c ipeOld = ipeOldMap.get(ipeNew.Id);
                
                if (String.isNotBlank(ipeNew.reduivy__Contact__c) &&
                    ipeNew.reduivy__Enrollment_Status__c != ipeOld.reduivy__Enrollment_Status__c &&
                    !IPESTATUS_COMPLETED.contains(ipeOld.reduivy__Enrollment_Status__c) && 
                    IPESTATUS_COMPLETED.contains(ipeNew.reduivy__Enrollment_Status__c) &&
                    ipeNew.RecordTypeId == IPE_RTID_MASTER
                ) {
                    qualifiedContactIdSet.add(ipeNew.reduivy__Contact__c);
                }
            }

            if(!qualifiedContactIdSet.isEmpty()){
                setContactAlumni(qualifiedContactIdSet);
            }
        }
    }

    /**
     * @description This is to set the Contact Type to Alumni
     * @param qualifiedContactIdSet List of qualified contact ids
     * @return void
     */
    private void setContactAlumni(Set<Id> qualifiedContactIdSet) {

        //Get all IPE records for qualified contacts
        String ipeQuery = 'SELECT reduivy__Contact__c, reduivy__Enrollment_Status__c' +
                        ' FROM reduivy__Individual_Program_Enrollment__c' + 
                        ' WHERE RecordTypeId = :IPE_RTID_MASTER' +
                        ' AND reduivy__Contact__c IN :qualifiedContactIdSet' +
                        ' AND reduivy__Contact__r.reduivy__Contact_Type__c = :contactTypeStudent';

        Map<String, Object> ipeBindParams = new Map<String, Object>{
            'IPE_RTID_MASTER' => IPE_RTID_MASTER,
            'qualifiedContactIdSet' => qualifiedContactIdSet,
            'contactTypeStudent' => CON_Helper.CONTACT_TYPE_STUDENT
        };

        Set<Id> studentContactIds = new Set<Id>();
        //Get contacts with at least one in-progress master IPE
        Set<Id> inProgressContactIdSet = new Set<Id>();

        for (reduivy__Individual_Program_Enrollment__c ipe : (List<reduivy__Individual_Program_Enrollment__c>) Database.queryWithBinds(ipeQuery, ipeBindParams, AccessLevel.USER_MODE)) {
            
            if (String.isNotBlank(ipe.reduivy__Contact__c)) {
                studentContactIds.add(ipe.reduivy__Contact__c);

                if (IPESTATUS_INPROGRESS.contains(ipe.reduivy__Enrollment_Status__c)) {
                    inProgressContactIdSet.add(ipe.reduivy__Contact__c);
                }
            }
        }

        //Set contact type to alumni
        if (!studentContactIds.isEmpty()) {
            List<Contact> updateContactList = new List<Contact>();

            for (Id contactId : studentContactIds) {
                if (!inProgressContactIdSet.contains(contactId)) {
                    Contact con = new Contact(Id = contactId);
                    con.reduivy__Contact_Type__c = CONTACT_TYPE_ALUMNI;
                    updateContactList.add(con);
                }
            }
                
            if(!updateContactList.isEmpty()){
                REDU_Database_UTIL.doUpdate(updateContactList);
            }
        }
    }
}