/**
 * @author      WDCi (dblack)
 * @date        Nov 2023
 * @group       Trigger executable
 * @description Individual Plan Structure: set the primary study unit
 * @changehistory
 * ISS-001764 06-11-2023 dblack - new class
 */
public inherited sharing class IPS_SetPrimary_EXE extends REDU_TriggerExecutable {

    /*
     * @description Individual plan structure unit record type Id
     */
    static final Id IPSU_RECORDTYPE_ID = IPS_Helper.getUnitRecordTypeId();


    /**
     * @description List of completed statuses for individual plan structure unit
     */
    static List<String> ipsuCompletedStatuses = IPS_Helper.getUnitCompletedStatuses();
    
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

        if ((operationType == TriggerOperation.BEFORE_INSERT) && 
			(REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER))
        ) {

            // If multiple ipsu records for the same study unit are set as primary in the same transaction, we take 
            // the first one and unset the rest
            Set<String> ipsuPrimarySet = new Set<String>();
            for (reduivy__Individual_Plan_Structure__c ipsu : (List<reduivy__Individual_Plan_Structure__c>) newList) {
                if ((ipsu.RecordTypeId == IPSU_RECORDTYPE_ID) && 
                    (String.isNotBlank(ipsu.reduivy__Target_Unit_Id__c)) && 
                    (isNewlyPrimaryOrPrimaryAndIpeChanged(null, ipsu))
                ) {

                    String identifier = getIdentifierKey(ipsu);
                    if (ipsuPrimarySet.contains(identifier)) {
                        setNonPrimaryIpsuInfo(ipsu);
                    } else {
                        ipsu.reduivy__Credits_Contribution__c = IPS_Helper.CREDITS_CONTRIBUTION_YES;
                    }

                    // ipsu.reduivy__Revalidate_Completion__c = true; //we should not need this anymore to avoid triggering the BeforeUpdate event for IPS_UnitIpsCompletion_EXE
                    ipsuPrimarySet.add(identifier);
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

        if ((operationType == TriggerOperation.AFTER_INSERT) && 
			(REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER))
        ) {

            // If there is a newly promoted primary ipsu record, unset the old one
            List<reduivy__Individual_Plan_Structure__c> ipsuList = new List<reduivy__Individual_Plan_Structure__c>();

            for (reduivy__Individual_Plan_Structure__c ipsu : (List<reduivy__Individual_Plan_Structure__c>) newList) {
                if ((ipsu.RecordTypeId == IPSU_RECORDTYPE_ID) && (String.isNotBlank(ipsu.reduivy__Target_Unit_Id__c)) && 
                    (isNewlyPrimaryOrPrimaryAndIpeChanged(null, ipsu))
                ) {
                    ipsuList.add(ipsu);
                }
            }

            if (!ipsuList.isEmpty()) {
                updatePrimaryIpsu(ipsuList);
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

        if ((operationType == TriggerOperation.BEFORE_UPDATE) && 
			(REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER))
        ) {

            // If multiple ipsu records for the same study unit are set as primary in the same transaction, we take 
            // the first one and unset the rest
            Set<String> ipsuPrimarySet = new Set<String>();
            for (reduivy__Individual_Plan_Structure__c ipsuNew : (List<reduivy__Individual_Plan_Structure__c>) newList) {
                reduivy__Individual_Plan_Structure__c ipsuOld = (reduivy__Individual_Plan_Structure__c) oldMap.get(ipsuNew.Id);
                
                if ((ipsuNew.RecordTypeId == IPSU_RECORDTYPE_ID) && (String.isNotBlank(ipsuNew.reduivy__Target_Unit_Id__c)) && 
                    (isNewlyPrimaryOrPrimaryAndIpeChanged(ipsuOld, ipsuNew))
                ) {

                    String identifier = getIdentifierKey(ipsuNew);
                    if (ipsuPrimarySet.contains(identifier)) {
                        setNonPrimaryIpsuInfo(ipsuNew);
                    } else {
                        ipsuNew.reduivy__Credits_Contribution__c = IPS_Helper.CREDITS_CONTRIBUTION_YES;
                    }

                    // ipsuNew.reduivy__Revalidate_Completion__c = true; //we should not need this anymore to avoid triggering the BeforeUpdate event for IPS_UnitIpsCompletion_EXE
                    ipsuPrimarySet.add(identifier);
                }
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

        if ((operationType == TriggerOperation.AFTER_UPDATE) && 
			(REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER))
        ) {

            // If there is a newly promoted primary ipsu record, unset the old one
            List<reduivy__Individual_Plan_Structure__c> ipsuList = new List<reduivy__Individual_Plan_Structure__c>();
            for (reduivy__Individual_Plan_Structure__c ipsuNew : (List<reduivy__Individual_Plan_Structure__c>) newList) {
                reduivy__Individual_Plan_Structure__c ipsuOld = (reduivy__Individual_Plan_Structure__c) oldMap.get(ipsuNew.Id);
                
                if ((ipsuNew.RecordTypeId == IPSU_RECORDTYPE_ID) && (String.isNotBlank(ipsuNew.reduivy__Target_Unit_Id__c)) && 
                    (isNewlyPrimaryOrPrimaryAndIpeChanged(ipsuOld, ipsuNew))
                ) {
                    ipsuList.add(ipsuNew);
                }
            }

            if (!ipsuList.isEmpty()) {
                updatePrimaryIpsu(ipsuList);
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

        if ((operationType == TriggerOperation.AFTER_DELETE) && 
			(REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER))
        ) {

            // If a primary ipsu unit is deleted, we will try to reevaluate the siblings to ensure the credits earned are regranted
            List<reduivy__Individual_Plan_Structure__c> ipsuList = new List<reduivy__Individual_Plan_Structure__c>();
            for (reduivy__Individual_Plan_Structure__c ipsu : (List<reduivy__Individual_Plan_Structure__c>) oldList) {
                if ((ipsu.RecordTypeId == IPSU_RECORDTYPE_ID) && 
                    (ipsu.reduivy__Primary__c) && (ipsuCompletedStatuses.contains(ipsu.reduivy__Status__c)) && 
                    (ipsu.reduivy__Credits_Contribution__c == IPS_Helper.CREDITS_CONTRIBUTION_YES)
                ) {
                    ipsuList.add(ipsu);
                }
            }

            if (!ipsuList.isEmpty()) {
                revalidateNonPrimaryIpsu(ipsuList);
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

        if ((operationType == TriggerOperation.AFTER_UNDELETE) && 
			(REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.REDUUSER))
        ) {

            // If there is a newly promoted primary ipsu record, unset the old one
            List<reduivy__Individual_Plan_Structure__c> ipsuList = new List<reduivy__Individual_Plan_Structure__c>();
            for (reduivy__Individual_Plan_Structure__c ipsu : (List<reduivy__Individual_Plan_Structure__c>) newList) {
                if ((ipsu.RecordTypeId == IPSU_RECORDTYPE_ID) && (String.isNotBlank(ipsu.reduivy__Target_Unit_Id__c)) && 
                    (isNewlyPrimaryOrPrimaryAndIpeChanged(null, ipsu))) {
                    ipsuList.add(ipsu);
                }
            }

            if (!ipsuList.isEmpty()) {
                updatePrimaryIpsu(ipsuList);
            }
        }
    }

    /**
     * @description Build the identification key using reduivy__Individual_Program_Enrollment__c + '_' + reduivy__Target_Unit_Id__c
     * @param ipsu reduivy__Individual_Plan_Structure__c
     * @return String
     */
    private String getIdentifierKey(reduivy__Individual_Plan_Structure__c ipsu) {
        return ipsu.reduivy__Individual_Program_Enrollment__c + '_' + ipsu.reduivy__Target_Unit_Id__c;
    }

    /**
     * @description For non primary ipsu records, uncheck the Primary checkbox and set the Credits Earned to 0 if it has value
     */
    private void setNonPrimaryIpsuInfo(reduivy__Individual_Plan_Structure__c ipsu) {

        ipsu.reduivy__Primary__c = false;
        // ipsu.reduivy__Revalidate_Completion__c = true; //we should not need this anymore to avoid triggering the BeforeUpdate event for IPS_UnitIpsCompletion_EXE
        
        if ((ipsuCompletedStatuses.contains(ipsu.reduivy__Status__c)) && (String.isBlank(ipsu.reduivy__Credits_Contribution__c) || ipsu.reduivy__Credits_Contribution__c == IPS_Helper.CREDITS_CONTRIBUTION_YES)) {
            ipsu.reduivy__Credits_Contribution__c = IPS_Helper.CREDITS_CONTRIBUTION_NO;
        }
    }

    /**
     * @description Determine if the ipsu is a new primary or is a primary that has a changed ipe
     */
    private Boolean isNewlyPrimaryOrPrimaryAndIpeChanged(reduivy__Individual_Plan_Structure__c ipsuOld, reduivy__Individual_Plan_Structure__c ipsuNew) {
        
        Boolean wasPrimary = ((ipsuOld != null) && (ipsuOld.reduivy__Primary__c));
        Boolean isPrimary = ((ipsuNew != null) && (ipsuNew.reduivy__Primary__c));
        Id ipeOldId = (ipsuOld != null) ? ipsuOld.reduivy__Individual_Program_Enrollment__c : null;
        Id ipeNewId = (ipsuNew != null) ? ipsuNew.reduivy__Individual_Program_Enrollment__c : null;

        Boolean ipeChange = ((ipsuOld != null) && (ipeOldId != ipeNewId));

        return (isPrimary && String.isNotBlank(ipsuNew.reduivy__Individual_Program_Enrollment__c)) && ((!wasPrimary) || (ipeChange));
    }

    /**
     * @description This is to update the other related ipsu records when a new primary ipsu is promoted
     * @param ipsuList List<reduivy__Individual_Plan_Structure__c>
     */
    private void updatePrimaryIpsu(List<reduivy__Individual_Plan_Structure__c> ipsuList) {

        Set<Id> ipeIdSet = new Set<Id>();
        Set<String> sunIdSet = new Set<String>();
        Map<String, reduivy__Individual_Plan_Structure__c> ipsuPrimaryMap = new Map<String, reduivy__Individual_Plan_Structure__c>();
        
        for (reduivy__Individual_Plan_Structure__c ipsu : ipsuList) {
            if (String.isNotBlank(ipsu.reduivy__Individual_Program_Enrollment__c)) {
                ipeIdSet.add(ipsu.reduivy__Individual_Program_Enrollment__c);
            }

            if (String.isNotBlank(ipsu.reduivy__Target_Unit_Id__c)) {
                sunIdSet.add(ipsu.reduivy__Target_Unit_Id__c);
                String identifier = getIdentifierKey(ipsu);
                ipsuPrimaryMap.put(identifier, ipsu);
            }
        }

        List<reduivy__Individual_Plan_Structure__c> ipsuUpdateList = new List<reduivy__Individual_Plan_Structure__c>();
        for (reduivy__Individual_Plan_Structure__c ipsuSibling : [
            SELECT  Id,
            reduivy__Primary__c,
            reduivy__Credits_Earned__c,
            reduivy__Credits_Contribution__c,
            reduivy__Target_Unit_Id__c,
            reduivy__Individual_Program_Enrollment__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPSU_RECORDTYPE_ID
            AND reduivy__Individual_Program_Enrollment__c IN :ipeIdSet
            AND reduivy__Target_Unit_Id__c IN :sunIdSet
            AND Id NOT IN :ipsuList
            WITH USER_MODE
            ORDER BY reduivy__Sequence_Key__c ASC NULLS LAST, Name ASC
        ]) {
            if ((ipsuSibling.reduivy__Primary__c) || 
                ((!ipsuSibling.reduivy__Primary__c) && (String.isBlank(ipsuSibling.reduivy__Credits_Contribution__c) || ipsuSibling.reduivy__Credits_Contribution__c == IPS_Helper.CREDITS_CONTRIBUTION_YES))
            ) {

                String identifier = getIdentifierKey(ipsuSibling);

                if (ipsuPrimaryMap.containsKey(identifier)) {
                    setNonPrimaryIpsuInfo(ipsuSibling);
                    
                    reduivy__Individual_Plan_Structure__c ipsuUpdate = new reduivy__Individual_Plan_Structure__c();
                    ipsuUpdate.Id = ipsuSibling.Id;
                    ipsuUpdate.reduivy__Primary__c = ipsuSibling.reduivy__Primary__c;
                    // ipsuUpdate.reduivy__Revalidate_Completion__c = ipsuSibling.reduivy__Revalidate_Completion__c; //we should not need this anymore to avoid triggering the BeforeUpdate event for IPS_UnitIpsCompletion_EXE
                    ipsuUpdate.reduivy__Credits_Contribution__c = ipsuSibling.reduivy__Credits_Contribution__c;
                    ipsuUpdateList.add(ipsuUpdate);
                }
            }
        }

        if (!ipsuUpdateList.isEmpty()) {
            if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.STUDENT)) {
                //Update using system mode as the fields are non editable by student user
                REDU_SystemMode_UTIL.doUpdate(ipsuUpdateList);
            } else {
                REDU_Database_UTIL.doUpdate(ipsuUpdateList);
            }
        }
    }

    /**
     * @description This is to revalidate the related ipsu record when a primary record is deleted
     * @param ipsuList List<reduivy__Individual_Plan_Structure__c>
     */
    private void revalidateNonPrimaryIpsu(List<reduivy__Individual_Plan_Structure__c> ipsuList) {

        Set<Id> ipeIdSet = new Set<Id>();
        Set<String> sunIdSet = new Set<String>();
        Map<String, reduivy__Individual_Plan_Structure__c> ipsuDeletedPrimaryMap = new Map<String, reduivy__Individual_Plan_Structure__c>();
        
        for (reduivy__Individual_Plan_Structure__c ipsu : ipsuList) {
            ipeIdSet.add(ipsu.reduivy__Individual_Program_Enrollment__c);

            if (String.isNotBlank(ipsu.reduivy__Target_Unit_Id__c)) {
                sunIdSet.add(ipsu.reduivy__Target_Unit_Id__c);
                String identifier = getIdentifierKey(ipsu);
                ipsuDeletedPrimaryMap.put(identifier, ipsu);
            }
        }

        Set<String> ipsuKeyExistingAwardedSet = new Set<String>();
        List<reduivy__Individual_Plan_Structure__c> ipsuPotentialList = new List<reduivy__Individual_Plan_Structure__c>();
        List<reduivy__Individual_Plan_Structure__c> ipsuUpdateList = new List<reduivy__Individual_Plan_Structure__c>();

        // Only revalidate the other ipsu records if there are none with credits earned
        // Use a list here to preserve the sorting order
        // The sorting sequence has to be the same across all ipe classes: 
        // reduivy__Sequence_Key__c ASC NULLS LAST
        for (reduivy__Individual_Plan_Structure__c ipsuSibling : [
            SELECT  Id,
            reduivy__Primary__c,
            reduivy__Credits_Earned__c,
            reduivy__Credits_Contribution__c,
            reduivy__Target_Unit_Id__c,
            reduivy__Individual_Program_Enrollment__c,
            reduivy__Status__c
            FROM reduivy__Individual_Plan_Structure__c
            WHERE RecordTypeId = :IPSU_RECORDTYPE_ID
            AND reduivy__Individual_Program_Enrollment__c IN :ipeIdSet
            AND reduivy__Target_Unit_Id__c IN :sunIdSet
            AND reduivy__Status__c IN: IPS_Helper.getUnitCompletedStatuses()
            AND Id NOT IN :ipsuList
            WITH USER_MODE
            ORDER BY reduivy__Sequence_Key__c ASC NULLS LAST, Name ASC
        ]) {
            String identifier = getIdentifierKey(ipsuSibling);
            
            // Look for existing ipsu with credits earned
            if (ipsuSibling.reduivy__Credits_Contribution__c == IPS_Helper.CREDITS_CONTRIBUTION_YES) {
                ipsuKeyExistingAwardedSet.add(identifier);
            }

            ipsuPotentialList.add(ipsuSibling);
        }

        for (reduivy__Individual_Plan_Structure__c ipsuSibling : ipsuPotentialList) {
            String identifier = getIdentifierKey(ipsuSibling);

            // Ignore the ipsu for the same study unit that already has credits earned so that we don't revalidate them
            if (!ipsuKeyExistingAwardedSet.contains(identifier)) {
                reduivy__Individual_Plan_Structure__c ipsuUpdate = new reduivy__Individual_Plan_Structure__c();
                ipsuUpdate.Id = ipsuSibling.Id;
                ipsuUpdate.reduivy__Revalidate_Completion__c = true; //toggle the flag to retrigger the IPS_UnitIpsCompletion_EXE
                ipsuUpdateList.add(ipsuUpdate);
            }
        }

        if (!ipsuUpdateList.isEmpty()) {
            if (REDU_Permission_UTIL.hasPermission(REDU_Permission_UTIL.UserPermission.STUDENT)) {
                //Update using system mode as the fields are non editable by student user
                REDU_SystemMode_UTIL.doUpdate(ipsuUpdateList);
            } else {
                REDU_Database_UTIL.doUpdate(ipsuUpdateList);
            }
        }
    }
}