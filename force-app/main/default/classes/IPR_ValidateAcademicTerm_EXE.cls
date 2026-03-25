/**
 * @author      WDCi (Lean)
 * @date        Dec 2023
 * @group       Trigger Executable
 * @description To prevent duplicate individual academic progress with duplicate term and prevent user from changing the academic term to a different when there is related individual enrollment or individual pathway
 * @changehistory
 * ISS-001816 22-12-2023 Lean - new class
 */
public inherited sharing class IPR_ValidateAcademicTerm_EXE extends REDU_TriggerExecutable {
    
    /**
     * @description BeforeUpdate
     * @param operationType Trigger operation type enum
     * @param newList Trigger new list
     * @param newMap Trigger new map
     * @param oldList Trigger old list
     * @param oldMap Trigger old map
     * @param sobjResult DescribeSObjectResult for the trigger object
     */
    public override void executeBeforeInsert(System.TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap, Schema.DescribeSObjectResult sobjResult) {

        if (!newList.isEmpty()) {
            validateDuplicateAcademicTerm((List<reduivy__Individual_Academic_Progress__c>) newList);
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

        List<reduivy__Individual_Academic_Progress__c> validateChildList = new List<reduivy__Individual_Academic_Progress__c>();
        List<reduivy__Individual_Academic_Progress__c> validateDupStmList = new List<reduivy__Individual_Academic_Progress__c>();

        for (reduivy__Individual_Academic_Progress__c ipr : (List<reduivy__Individual_Academic_Progress__c>) newList) {
            reduivy__Individual_Academic_Progress__c oldIpr = (reduivy__Individual_Academic_Progress__c) oldMap.get(ipr.Id);

            if (ipr.reduivy__Academic_Term__c != oldIpr.reduivy__Academic_Term__c) {
                validateChildList.add(ipr);
                validateDupStmList.add(ipr);

            } else if (ipr.reduivy__Individual_Academic_Profile__c != oldIpr.reduivy__Individual_Academic_Profile__c) {
                validateDupStmList.add(ipr);
            }
        }

        if (!validateDupStmList.isEmpty()) {
            validateDuplicateAcademicTerm(validateChildList);
        }

        if (!validateChildList.isEmpty()) {
            validateAcademicProgressChildRecords(validateChildList);
        }
    }

    /**
     * @description Validate individual academic progress that has the same academic term
     * @param iprList
     * @return void
     */
    private void validateDuplicateAcademicTerm(List<reduivy__Individual_Academic_Progress__c> iprList) {

        Map<String, List<reduivy__Individual_Academic_Progress__c>> iprByIpfStm = new Map<String, List<reduivy__Individual_Academic_Progress__c>>();
        List<reduivy__Individual_Academic_Progress__c> qualifiedIprList = new List<reduivy__Individual_Academic_Progress__c>();

        Set<Id> ipfIds = new Set<Id>();
        Set<Id> stmIds = new Set<Id>();
        Set<Id> iprIds = new Set<Id>();

        //Compile the ipr in the current trigger context into a map
        for (reduivy__Individual_Academic_Progress__c ipr : iprList) {
            if (String.isNotBlank(ipr.Id)) {
                iprIds.add(ipr.Id);
            }

            if (String.isNotBlank(ipr.reduivy__Individual_Academic_Profile__c) && 
                String.isNotBlank(ipr.reduivy__Academic_Term__c)
            ) {
                ipfIds.add(ipr.reduivy__Individual_Academic_Profile__c);
                stmIds.add(ipr.reduivy__Academic_Term__c);

                String ipfStmKey = getIpfStmKey(ipr);
                
                if (iprByIpfStm.containsKey(ipfStmKey)) {
                    iprByIpfStm.get(ipfStmKey).add(ipr);
                } else {
                    iprByIpfStm.put(ipfStmKey, new List<reduivy__Individual_Academic_Progress__c>{ipr});
                }

                qualifiedIprList.add(ipr);
            }
        }

        //Query the other sibling ipr
        for (reduivy__Individual_Academic_Progress__c otherIpr: [SELECT Id,
            reduivy__Individual_Academic_Profile__c,
            reduivy__Academic_Term__c
            FROM reduivy__Individual_Academic_Progress__c
            WHERE reduivy__Individual_Academic_Profile__c IN: ipfIds
            AND reduivy__Academic_Term__c IN: stmIds
            AND Id NOT IN: iprIds
            WITH USER_MODE
        ]) {
            String ipfStmKey = getIpfStmKey(otherIpr);

            if (iprByIpfStm.containsKey(ipfStmKey)) {
                iprByIpfStm.get(ipfStmKey).add(otherIpr);
            } else {
                iprByIpfStm.put(ipfStmKey, new List<reduivy__Individual_Academic_Progress__c>{otherIpr});
            }
        }

        String iprObjectLabel = IPR_Helper.getObjectLabel();
        String academicTermFieldLabel = SObjectType.reduivy__Individual_Academic_Progress__c.fields.reduivy__Academic_Term__c.getLabel();

        //Check if the ipr's academic term is already existed
        for (reduivy__Individual_Academic_Progress__c ipr : qualifiedIprList) {
            String ipfStmKey = getIpfStmKey(ipr);

            if (iprByIpfStm.containsKey(ipfStmKey) &&
                iprByIpfStm.get(ipfStmKey).size() > 1
            ) {
                Set<String> dupIds = new Set<String>();

                for (reduivy__Individual_Academic_Progress__c dupIpr : iprByIpfStm.get(ipfStmKey)) {
                    //ignore the record if the id is blank (new record) or it is the same as the current record
                    if (String.isNotBlank(dupIpr.Id) && dupIpr.Id != ipr.Id) {
                        dupIds.add(dupIpr.Id);
                    }
                }

                ipr.addError(String.format(Label.Duplicate_Record_Error, new List<String>{iprObjectLabel, academicTermFieldLabel, String.join(dupIds, ', ')}));
            }
        }
    }

    /**
     * @description Return individual academic profile + academic term key
     * @param ipr
     * @return String
     */
    private String getIpfStmKey(reduivy__Individual_Academic_Progress__c ipr) {
        return ipr.reduivy__Individual_Academic_Profile__c + '_' + ipr.reduivy__Academic_Term__c;
    }

    /**
     * @description Validate individual academic progress's academic term to prevent user from changing the academic term to a different when there is related individual enrollment or individual pathway
     * @param iprList
     * @return void
     */
    private void validateAcademicProgressChildRecords(List<reduivy__Individual_Academic_Progress__c> iprList) {
        
        Map<Id, List<reduivy__Individual_Enrollment__c>> ienByIprMap = new Map<Id, List<reduivy__Individual_Enrollment__c>>();
        Map<Id, List<reduivy__Individual_Pathway__c>> ipwByIprMap = new Map<Id, List<reduivy__Individual_Pathway__c>>();

        for (reduivy__Individual_Enrollment__c ien : [SELECT Id,
            reduivy__Academic_Term_Id__c,
            reduivy__Individual_Academic_Progress__c
            FROM reduivy__Individual_Enrollment__c
            WHERE reduivy__Individual_Academic_Progress__c IN: iprList
            WITH USER_MODE
        ]) {
            if (ienByIprMap.containsKey(ien.reduivy__Individual_Academic_Progress__c)) {
                ienByIprMap.get(ien.reduivy__Individual_Academic_Progress__c).add(ien);
            } else {
                ienByIprMap.put(ien.reduivy__Individual_Academic_Progress__c, new List<reduivy__Individual_Enrollment__c>{ien});
            }
        }

        for (reduivy__Individual_Pathway__c ipw : [SELECT Id,
            reduivy__Academic_Term__c,
            reduivy__Individual_Academic_Progress__c
            FROM reduivy__Individual_Pathway__c
            WHERE reduivy__Individual_Academic_Progress__c IN: iprList
            WITH USER_MODE
        ]) {
            if (ipwByIprMap.containsKey(ipw.reduivy__Individual_Academic_Progress__c)) {
                ipwByIprMap.get(ipw.reduivy__Individual_Academic_Progress__c).add(ipw);
            } else {
                ipwByIprMap.put(ipw.reduivy__Individual_Academic_Progress__c, new List<reduivy__Individual_Pathway__c>{ipw});
            }
        }

        for (reduivy__Individual_Academic_Progress__c ipr : iprList) {
            
            Boolean hasInvalidIen = false;
            Boolean hasInvalidIpw = false;

            if (String.isBlank(ipr.reduivy__Academic_Term__c)) {
                if (ienByIprMap.containsKey(ipr.Id)) {
                    hasInvalidIen = true;
                }

                if (ipwByIprMap.containsKey(ipr.Id)) {
                    hasInvalidIpw = true;
                }

            } else {
                if (ienByIprMap.containsKey(ipr.Id)) {
                    for (reduivy__Individual_Enrollment__c ien : ienByIprMap.get(ipr.Id)) {
                        if (String.isNotBlank(ien.reduivy__Academic_Term_Id__c) && 
                            ien.reduivy__Academic_Term_Id__c != ipr.reduivy__Academic_Term__c
                        ) {
                            hasInvalidIen = true;
                            break;
                        }
                    }
                }

                if (ipwByIprMap.containsKey(ipr.Id)) {
                    for (reduivy__Individual_Pathway__c ipw : ipwByIprMap.get(ipr.Id)) {
                        if (String.isNotBlank(ipw.reduivy__Academic_Term__c) && 
                            ipw.reduivy__Academic_Term__c != ipr.reduivy__Academic_Term__c
                        ) {
                            hasInvalidIpw = true;
                            break;
                        }
                    }
                }
            }

            if (hasInvalidIen || hasInvalidIpw) {
                List<String> affectedChilds = new List<String>();
                if (hasInvalidIen) {
                    affectedChilds.add(IEN_Helper.getObjectPluralLabel());
                }

                if (hasInvalidIpw) {
                    affectedChilds.add(IPW_Helper.getObjectPluralLabel());
                }

                String errorMsg = String.format(Label.Cannot_Update_Field_Child_Error, new List<String>{SObjectType.reduivy__Individual_Academic_Progress__c.fields.reduivy__Academic_Term__c.getLabel(), String.join(affectedChilds, ', ')});
                ipr.addError(errorMsg);
            }
        }
    }
}