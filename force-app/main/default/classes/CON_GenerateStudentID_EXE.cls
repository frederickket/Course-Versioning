/**
 * @author      WDCi (XW)
 * @date        Mar 2025
 * @group       Trigger executable
 * @description Generate Student id based on System Variable when "Generate Student ID" is checked
 * @changehistory
 * ISS-002089 04-03-2025 XW - new class
 */
public inherited sharing class CON_GenerateStudentID_EXE extends REDU_TriggerExecutable {
    
    public static final String KEY_STUDENT_ID = 'STUDENT_ID_COUNTER';
    
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
        
        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN)){
            List<SObject> workingList = new List<SObject>();
            for (Contact objNew : (List<Contact>) newList) {
                if( objNew.reduivy__Contact_Type__c == CON_Helper.CONTACT_TYPE_STUDENT &&
                    objNew.reduivy__Generate_Student_ID__c == true && 
                    String.isBlank(objNew.reduivy__Student_ID__c)){

                    workingList.add(objNew);
                }
            }

            if(!workingList.isEmpty()) {
                generateStudentId(workingList);
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

        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN)) {

            List<Contact> workingList = new List<Contact>();
            for (Contact objNew : (List<Contact>) newList) {
                Contact objOld = (Contact) oldMap.get(objNew.Id);

                if (objNew.reduivy__Contact_Type__c == CON_Helper.CONTACT_TYPE_STUDENT &&
                    objNew.reduivy__Generate_Student_ID__c != objOld.reduivy__Generate_Student_ID__c &&
                    objNew.reduivy__Generate_Student_ID__c == true &&
                    String.isBlank(objNew.reduivy__Student_ID__c)) {

                    workingList.add(objNew);
                }
            }
            
            if(!workingList.isEmpty()) {
                generateStudentId(workingList);
            }
        }
    }

    /**
     * @description generate student id for contacts
     * @param  workingList the students to generate student id for
     */
    static void generateStudentId(List<Contact> workingList) {
        List<String> generatedIdList = SYV_Helper.generateSequenceNumber(workingList.size(), KEY_STUDENT_ID);
        
        if(!generatedIdList.isEmpty()) {
            Integer recordCounter = 0;
            for (Contact contact : workingList) {
                contact.reduivy__Student_ID__c = generatedIdList[recordCounter];
                recordCounter++;
            }
        }

    }

}