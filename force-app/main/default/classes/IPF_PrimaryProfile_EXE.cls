/**
 * @author      WDCi (Lean)
 * @date        Dec 2023
 * @group       Trigger Executable
 * @description This is to handle the change of primary individual academic profile
 * @changehistory
 * ISS-001816 19-12-2023 Lean - new class
 */
public inherited sharing class IPF_PrimaryProfile_EXE extends REDU_TriggerExecutable {
    
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
        
        if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.ADMIN)) {

            Set<Id> contactWithPrimaryIpf = new Set<Id>();
            for (reduivy__Individual_Academic_Profile__c ipf : (List<reduivy__Individual_Academic_Profile__c>) newList) {
                if (String.isNotBlank(ipf.reduivy__Contact__c) && ipf.reduivy__Primary__c) {
                    if (contactWithPrimaryIpf.contains(ipf.reduivy__Contact__c)) {
                        ipf.reduivy__Primary__c = false;
                    } else {
                        contactWithPrimaryIpf.add(ipf.reduivy__Contact__c);
                    }
                }
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

            Set<Id> contactWithPrimaryIpf = new Set<Id>();
            for (reduivy__Individual_Academic_Profile__c ipf : (List<reduivy__Individual_Academic_Profile__c>) newList) {
                reduivy__Individual_Academic_Profile__c oldIpf = (reduivy__Individual_Academic_Profile__c) oldMap.get(ipf.Id);

                if (String.isNotBlank(ipf.reduivy__Contact__c) && ipf.reduivy__Primary__c && ipf.reduivy__Primary__c != oldIpf.reduivy__Primary__c) {
                    if (contactWithPrimaryIpf.contains(ipf.reduivy__Contact__c)) {
                        ipf.reduivy__Primary__c = false;
                    } else {
                        contactWithPrimaryIpf.add(ipf.reduivy__Contact__c);
                    }
                }
            }
        }

    }

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

            List<reduivy__Individual_Academic_Profile__c> workingIpfList = new List<reduivy__Individual_Academic_Profile__c>();

            for (reduivy__Individual_Academic_Profile__c ipf : (List<reduivy__Individual_Academic_Profile__c>) newList) {
                if (isNewlyPrimaryOrPrimaryAndContactChanged(null, ipf)) {
                    workingIpfList.add(ipf);
                }
            }

            unsetOtherPrimaryProfile(workingIpfList);

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

            List<reduivy__Individual_Academic_Profile__c> workingIpfList = new List<reduivy__Individual_Academic_Profile__c>();

            for (reduivy__Individual_Academic_Profile__c ipf : (List<reduivy__Individual_Academic_Profile__c>) newList) {
                reduivy__Individual_Academic_Profile__c oldIpf = (reduivy__Individual_Academic_Profile__c) oldMap.get(ipf.Id);

                if (isNewlyPrimaryOrPrimaryAndContactChanged(oldIpf, ipf)) {
                    workingIpfList.add(ipf);
                }
            }

            unsetOtherPrimaryProfile(workingIpfList);
        }

    }

    /**
     * @description This is to validate if the new academic profile is primary or the existing academic profile is changed to primary
     * @param oldIpf Old individual academic profile record
     * @param newIpf New individual academic profile record
     * @return Boolean
     */
    private Boolean isNewlyPrimaryOrPrimaryAndContactChanged(reduivy__Individual_Academic_Profile__c oldIpf, reduivy__Individual_Academic_Profile__c newIpf) {
        Boolean wasPrimary = ((oldIpf != null) && (oldIpf.reduivy__Primary__c));
        Boolean isPrimary = ((newIpf != null) && (newIpf.reduivy__Primary__c));

        return (isPrimary) && (!wasPrimary);
    }

    /**
     * @description This is to unset other primary individual academic profile
     * @param newPrimaryProfiles List of new primary individual academic profile
     * @return void
     */
    private void unsetOtherPrimaryProfile(List<reduivy__Individual_Academic_Profile__c> newPrimaryProfiles) {

        if (!newPrimaryProfiles.isEmpty()) {
            Set<Id> ipfIds = new Set<Id>();

            Map<Id, List<reduivy__Individual_Academic_Profile__c>> contactIpfs = new Map<Id, List<reduivy__Individual_Academic_Profile__c>>();
            for (reduivy__Individual_Academic_Profile__c ipf : newPrimaryProfiles) {
                
                if (String.isNotBlank(ipf.reduivy__Contact__c)) {
                    ipfIds.add(ipf.Id);

                    if (contactIpfs.containsKey(ipf.reduivy__Contact__c)) {
                        contactIpfs.get(ipf.reduivy__Contact__c).add(ipf);
                    } else {
                        contactIpfs.put(ipf.reduivy__Contact__c, new List<reduivy__Individual_Academic_Profile__c>{ipf});
                    }
                }
            }

            List<reduivy__Individual_Academic_Profile__c> ipfUpdateList = new List<reduivy__Individual_Academic_Profile__c>();
            for (reduivy__Individual_Academic_Profile__c otherIpf : [SELECT Id, reduivy__Primary__c, reduivy__Contact__c
                FROM reduivy__Individual_Academic_Profile__c
                WHERE reduivy__Contact__c IN: contactIpfs.keySet()
                AND Id NOT IN: ipfIds
                WITH USER_MODE
            ]) {
                otherIpf.reduivy__Primary__c = false;
                ipfUpdateList.add(otherIpf);
            }

            REDU_Database_UTIL.doUpdate(ipfUpdateList, contactIpfs, 'reduivy__Contact__c', false);
        }
    }
	
}