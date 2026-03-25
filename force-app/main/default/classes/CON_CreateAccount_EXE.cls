/**
 * @author      WDCi (dblack)
 * @date        Oct 2023
 * @group       Trigger executable
 * @description Create an administrative account for any new contacts that do not have an account linked
 * @changehistory
 * ISS-001618 02-10-2023 dblack - new class
 * 
 */
public inherited sharing class CON_CreateAccount_EXE extends REDU_TriggerExecutable {
    
	/**
     * @description BeforeInsert: Create an account for a new contact that does not have an account linked
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeInsert(
        System.TriggerOperation operationType, 
        List<SObject> newList, Map<Id, SObject> newMap, 
        List<SObject> oldList, Map<Id, SObject> oldMap, 
        Schema.DescribeSObjectResult sobjResult) {

        if (operationType == TriggerOperation.BEFORE_INSERT) {

            // Get the contacts that do not have an account
            List<Contact> conList = new List<Contact>();
            for (Contact con : (List<Contact>) newList) {
                if (String.isBlank(con.AccountId)) {
                    conList.add(con);
                }
            }
            if (!conList.isEmpty()) {

                // Create accounts for the contacts
                Map<Integer, Account> accMap = CON_Helper.getNewAccountMap(conList);

                // Assign the new accounts to the contacts
                Integer conKey;
                for (Contact con : conList) {
                    conKey = conList.indexOf(con);
                    con.AccountId = accMap.get(conKey).Id;
                }
            }
        }
    }
}