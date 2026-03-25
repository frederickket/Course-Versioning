/**
 * @author      WDCi (VTan)
 * @date        Mar 2024
 * @group       Trigger executable
 * @description Update contact type to Student when an applicant enrolled to a program.
 * @changehistory
 * ISS-001909 21-03-202 VTan - new class
 */
public inherited sharing class IPE_UpdateContactType_EXE extends REDU_TriggerExecutable {

    private static final List<String> IPESTATUS_INPROGRESS = IPE_Helper.getInProgressStatuses();
    private static final Id IPE_RTID_MASTER = IPE_Helper.getMasterEnrollmentRecordTypeId();

    /**
     * @description BeforeUpdate: prevent the change of program status from any status to draft
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterInsert(
        System.TriggerOperation operationType, 
        List<SObject> newList, Map<Id, SObject> newMap, 
        List<SObject> oldList, Map<Id, SObject> oldMap, 
        Schema.DescribeSObjectResult sobjResult) {

        if (operationType == TriggerOperation.AFTER_INSERT && REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN)) {

            List<reduivy__Individual_Program_Enrollment__c> qualifiedIpeList = new List<reduivy__Individual_Program_Enrollment__c>();
            for (reduivy__Individual_Program_Enrollment__c ipeNew : (List<reduivy__Individual_Program_Enrollment__c>) newList) {
                
                if (IPESTATUS_INPROGRESS.contains(ipeNew.reduivy__Enrollment_Status__c) && ipeNew.RecordTypeId == IPE_RTID_MASTER) {
                    qualifiedIpeList.add(ipeNew);
                }
            }

            if(!qualifiedIpeList.isEmpty()){
                updateContactType(qualifiedIpeList);
            }
        }
    }

    /**
     * @description BeforeUpdate: prevent the change of program status from any status to draft
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeAfterUpdate(
        System.TriggerOperation operationType, 
        List<SObject> newList, Map<Id, SObject> newMap, 
        List<SObject> oldList, Map<Id, SObject> oldMap, 
        Schema.DescribeSObjectResult sobjResult) {

        if (operationType == TriggerOperation.AFTER_UPDATE && REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN)) {

            Map<Id, reduivy__Individual_Program_Enrollment__c> ipeOldMap = 
                new Map<Id, reduivy__Individual_Program_Enrollment__c>((List<reduivy__Individual_Program_Enrollment__c>) oldList);

            List<reduivy__Individual_Program_Enrollment__c> qualifiedIpeList = new List<reduivy__Individual_Program_Enrollment__c>();
            for (reduivy__Individual_Program_Enrollment__c ipeNew : (List<reduivy__Individual_Program_Enrollment__c>) newList) {
                reduivy__Individual_Program_Enrollment__c ipeOld = ipeOldMap.get(ipeNew.Id);
                
                if (ipeNew.reduivy__Enrollment_Status__c != ipeOld.reduivy__Enrollment_Status__c && 
                    IPESTATUS_INPROGRESS.contains(ipeNew.reduivy__Enrollment_Status__c) &&
                    ipeNew.RecordTypeId == IPE_RTID_MASTER){
                    
                    qualifiedIpeList.add(ipeNew);
                }
            }

            if(!qualifiedIpeList.isEmpty()){
                updateContactType(qualifiedIpeList);
            }
        }
    }

    /**
     * @description This is to check and update 
     * @param qualifiedIpeList List of qualified individual program enrollment records
     * @return void
     */
    private void updateContactType(List<reduivy__Individual_Program_Enrollment__c> qualifiedIpeList) {

        // Get contact type value from the contact lookup field
        Map<Id, List<reduivy__Individual_Program_Enrollment__c>> contactIdIpes= new Map<Id, List<reduivy__Individual_Program_Enrollment__c>>();
        for(reduivy__Individual_Program_Enrollment__c ipe : qualifiedIpeList){

            if(contactIdIpes.containsKey(ipe.reduivy__Contact__c)){
                contactIdIpes.get(ipe.reduivy__Contact__c).add(ipe);
            }else{
                contactIdIpes.put(ipe.reduivy__Contact__c, new List<reduivy__Individual_Program_Enrollment__c>{ipe});
            }
        }

        String contactQuery = 'SELECT Id, reduivy__Contact_Type__c' +
                            ' FROM Contact' + 
                            ' WHERE Id IN: contactIds';

        Map<String, Object> conBindParams = new Map<String, Object>{
            'contactIds' => contactIdIpes.keySet()
        };

        List<Contact> updateContactList = new List<Contact>();
        String contactTypeStudent = CON_Helper.CONTACT_TYPE_STUDENT;
        String contactTypeApplicant = CON_Helper.CONTACT_TYPE_APPLICANT;
        for(Contact con : (List<Contact>) Database.queryWithBinds(contactQuery, conBindParams, AccessLevel.USER_MODE)){

            if(con.reduivy__Contact_Type__c == contactTypeApplicant){

                con.reduivy__Contact_Type__c = contactTypeStudent;
                updateContactList.add(con);
            }
        }
        
        if(!updateContactList.isEmpty()){
            REDU_Database_UTIL.doUpdate(updateContactList, contactIdIpes, 'Id', false);
        }
    }
}