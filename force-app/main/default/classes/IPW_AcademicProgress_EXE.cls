/**
 * @author      WDCi (Lean)
 * @date        Dec 2023
 * @group       Trigger Executable
 * @description This handles the creation of individual academic progress when an individual pathway has academic term set.
 * @changehistory
 * ISS-001816 29-12-2023 Lean - new class
 */
public inherited sharing class IPW_AcademicProgress_EXE extends REDU_TriggerExecutable {
    
    /**
     * @description Individual program enrollment object label
     */
    private static final String IPE_OBJECT_LABEL = IPE_Helper.getObjectLabel();
    
    /**
     * @description Individual academic program object label
     */
    private static final String IPF_OBJECT_LABEL = IPF_Helper.getObjectLabel();

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
            
            List<reduivy__Individual_Pathway__c> workingIpwList = new List<reduivy__Individual_Pathway__c>();

            for (reduivy__Individual_Pathway__c ipw : (List<reduivy__Individual_Pathway__c>) newList) {
                if (String.isNotBlank(ipw.reduivy__Academic_Term__c)) {
                    workingIpwList.add(ipw);
                }
            }

            if (!workingIpwList.isEmpty()) {
                setAcademicProgress(workingIpwList);
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
            
            List<reduivy__Individual_Pathway__c> workingIpwList = new List<reduivy__Individual_Pathway__c>();

            for (reduivy__Individual_Pathway__c ipw : (List<reduivy__Individual_Pathway__c>) newList) {
                reduivy__Individual_Pathway__c oldIpw = (reduivy__Individual_Pathway__c) oldMap.get(ipw.Id);

                if (String.isNotBlank(ipw.reduivy__Individual_Program_Enrollment__c) &&
                    String.isNotBlank(ipw.reduivy__Academic_Term__c) &&
                    ipw.reduivy__Academic_Term__c != oldIpw.reduivy__Academic_Term__c
                ) {
                    workingIpwList.add(ipw);
                }
            }

            if (!workingIpwList.isEmpty()) {
                setAcademicProgress(workingIpwList);
            }
        }

    }

    /**
     * @description Set the individual pathway with an individual academic progress that belongs to the same academic term.
     * @param ipwList Individual Pathway records
     * @return void
     */
    private void setAcademicProgress(List<reduivy__Individual_Pathway__c> ipwList) {

        Set<Id> ipeIds = new Set<Id>();
        Set<Id> stmIds = new Set<Id>();
        Set<Id> ipfIds = new Set<Id>();

        Map<String, List<reduivy__Individual_Pathway__c>> qualifiedIpwByProfileTerm = new Map<String, List<reduivy__Individual_Pathway__c>>();
        Map<String, reduivy__Individual_Academic_Progress__c> iprByProfileTerm = new Map<String, reduivy__Individual_Academic_Progress__c>();

        for (reduivy__Individual_Pathway__c ipw : ipwList) {
            if (String.isNotBlank(ipw.reduivy__Individual_Program_Enrollment__c)) {
                ipeIds.add(ipw.reduivy__Individual_Program_Enrollment__c);
            }

            if (String.isNotBlank(ipw.reduivy__Academic_Term__c)) {
                stmIds.add(ipw.reduivy__Academic_Term__c);
            }
        }

        // Get individual academic profile from ipe
        Map<Id, reduivy__Individual_Program_Enrollment__c> ipeMap = new Map<Id, reduivy__Individual_Program_Enrollment__c>([
            SELECT Id,
            Name,
            reduivy__Contact__c,
            reduivy__Individual_Academic_Profile__c
            FROM reduivy__Individual_Program_Enrollment__c
            WHERE Id IN: ipeIds
            WITH USER_MODE
        ]);

        for (reduivy__Individual_Pathway__c ipw : ipwList) {
            reduivy__Individual_Program_Enrollment__c ipe = ipeMap.get(ipw.reduivy__Individual_Program_Enrollment__c);

            if (String.isNotBlank(ipe.reduivy__Individual_Academic_Profile__c)) {
                // get the individual academic profile to query the related individual academic progress
                ipfIds.add(ipe.reduivy__Individual_Academic_Profile__c);

                String ipfStmKey = getIpfStmKey(ipe.reduivy__Individual_Academic_Profile__c, ipw.reduivy__Academic_Term__c);
                
                if (qualifiedIpwByProfileTerm.containsKey(ipfStmKey)) {
                    qualifiedIpwByProfileTerm.get(ipfStmKey).add(ipw);
                } else {
                    qualifiedIpwByProfileTerm.put(ipfStmKey, new List<reduivy__Individual_Pathway__c>{ipw});
                }
                
            } else {
                // throw error if the ipe doesn't have an individual academic profile set
                String recordUrl = REDU_OrganizationInfo_UTIL.getDomainUrl() + ipe.Id;
                String errorMsg = String.format(Label.Missing_Info_For_Record, new List<String>{IPF_OBJECT_LABEL, IPE_OBJECT_LABEL, recordUrl});
                ipw.addError(errorMsg);
            }
        }

        // Compile a map of individual academic progress with the key ipf.Id_stm.Id
        for (reduivy__Individual_Academic_Progress__c ipr : [SELECT Id,
            reduivy__Individual_Academic_Profile__c,
            reduivy__Academic_Term__c,
            reduivy__Recommended_Credits__c,
            reduivy__Max_Credits__c
            FROM reduivy__Individual_Academic_Progress__c
            WHERE reduivy__Individual_Academic_Profile__c IN: ipfIds
            AND reduivy__Academic_Term__c IN: stmIds
            WITH USER_MODE
            ORDER BY reduivy__Academic_Term__r.reduivy__Start_Date__c, reduivy__Academic_Term__r.reduivy__End_Date__c
        ]) {
            String ipfStmKey = getIpfStmKey(ipr.reduivy__Individual_Academic_Profile__c, ipr.reduivy__Academic_Term__c);

            iprByProfileTerm.put(ipfStmKey, ipr);
        }

        Map<String, reduivy__Individual_Academic_Progress__c> iprUpsertMap = new Map<String, reduivy__Individual_Academic_Progress__c>();

        for (String ipfStmKey : qualifiedIpwByProfileTerm.keySet()) {
            for (reduivy__Individual_Pathway__c ipw : qualifiedIpwByProfileTerm.get(ipfStmKey)) {
                
                if (!iprByProfileTerm.containsKey(ipfStmKey)) {
                    // create new ipr
                    // there could be multiple ipw needing a new ipr from the same ipf, we always take the first one as the template
                    reduivy__Individual_Program_Enrollment__c ipe = ipeMap.get(ipw.reduivy__Individual_Program_Enrollment__c);
                    
                    reduivy__Individual_Academic_Progress__c newIpr = new reduivy__Individual_Academic_Progress__c(
                        reduivy__Contact__c = ipe.reduivy__Contact__c,
                        reduivy__Individual_Academic_Profile__c = ipe.reduivy__Individual_Academic_Profile__c,
                        reduivy__Academic_Term__c = ipw.reduivy__Academic_Term__c,
                        reduivy__Max_Credits__c = ipw.reduivy__Max_Credits__c,
                        reduivy__Recommended_Credits__c = ipw.reduivy__Recommended_Credits__c
                    );

                    iprByProfileTerm.put(ipfStmKey, newIpr);

                    iprUpsertMap.put(ipfStmKey, newIpr);

                } else if (String.isNotBlank(iprByProfileTerm.get(ipfStmKey).Id)) {
                    // if found an existing ipr with id and null credits field e.g., those created in IEN_AcademicProgress_EXE, we will set it
                    reduivy__Individual_Academic_Progress__c existingIpr = iprByProfileTerm.get(ipfStmKey);
                    Boolean hasChanged = false;

                    if (existingIpr.reduivy__Max_Credits__c == null) {
                        existingIpr.reduivy__Max_Credits__c = ipw.reduivy__Max_Credits__c;
                        hasChanged = true;
                    }

                    if (existingIpr.reduivy__Recommended_Credits__c == null) {
                        existingIpr.reduivy__Recommended_Credits__c = ipw.reduivy__Recommended_Credits__c;
                        hasChanged = true;
                    }

                    if (hasChanged) {
                        iprByProfileTerm.put(ipfStmKey, existingIpr);
                        iprUpsertMap.put(ipfStmKey, existingIpr);
                    }
                }
            }
        }

        REDU_Database_UTIL.doUpsert(iprUpsertMap, qualifiedIpwByProfileTerm, false);

        for (String ipfStmKey : qualifiedIpwByProfileTerm.keySet()) {
            if (iprByProfileTerm.containsKey(ipfStmKey)) {
                for (reduivy__Individual_Pathway__c ipw : qualifiedIpwByProfileTerm.get(ipfStmKey)) {
                    ipw.reduivy__Individual_Academic_Progress__c = iprByProfileTerm.get(ipfStmKey).Id;
                }
            }
        }

    }

    /**
     * @description Return individual academic profile + academic term id key
     * @param ipfId
     * @param academicTermId
     * @return String
     */
    private String getIpfStmKey(Id ipfId, Id academicTermId) {
        return ipfId + '_' + academicTermId;
    }
	
}