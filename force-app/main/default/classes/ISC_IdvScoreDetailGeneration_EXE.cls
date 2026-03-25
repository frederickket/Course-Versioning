/**
 * @author      WDCi (XW)
 * @date        Aug 2025
 * @group       Application Scoring
 * @description create related individual score details when individual scores are created
 * @changehistory
 * ISS-002506 22-08-2025 XW - new class
 */

public inherited sharing class ISC_IdvScoreDetailGeneration_EXE extends REDU_TriggerExecutable {

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

            Map<Id, reduivy__Individual_Score__c> workingMap = new Map<Id, reduivy__Individual_Score__c>();
            for (reduivy__Individual_Score__c objNew : (List<reduivy__Individual_Score__c>) newList) {
                if(String.isNotBlank(objNew.reduivy__Study_Scoring_Config__c)) {
                    workingMap.put(objNew.Id, objNew);
                }
            }

            if(!workingMap.isEmpty()) {
                createRelatedIsd(workingMap);
            }
        }
    }
	
    /**
     * @description create the related individual score detail after the parent individual score is created
     * @param iscMap individual score map
     * @return void
     */
    private void createRelatedIsd(Map<Id, reduivy__Individual_Score__c> iscMap) {

        Map<Id, List<reduivy__Individual_Score__c>> scfToIscMap = new Map<Id, List<reduivy__Individual_Score__c>>();
        for(reduivy__Individual_Score__c isc : iscMap.values()) {
            if(!scfToIscMap.containsKey(isc.reduivy__Study_Scoring_Config__c)) {
                scfToIscMap.put(isc.reduivy__Study_Scoring_Config__c, new List<reduivy__Individual_Score__c>());
            }

            scfToIscMap.get(isc.reduivy__Study_Scoring_Config__c).add(isc);
        }

        Map<String, List<reduivy__Individual_Score_Detail__c>> parentIsdToIsdMap = new Map<String, List<reduivy__Individual_Score_Detail__c>>();

        //get the map that stores the relationship of the parent isd and child isd
        Map<Id, Map<Id, List<reduivy__Study_Scoring_Criteria__c>>> scrGroupMap = SCR_Helper.getGroupMap(scfToIscMap.keySet());

        for(reduivy__Individual_Score__c isc : iscMap.values()) {
            if(!scrGroupMap.containsKey(isc.reduivy__Study_Scoring_Config__c)) {
                //study scoring config can have no children study scoring criteria, or all of the children scr are inactive.
                //In this case we will just skip the creation of the isd
                continue;
            }
            Map<Id, List<reduivy__Study_Scoring_Criteria__c>> parentScrToScrMap = scrGroupMap.get(isc.reduivy__Study_Scoring_Config__c);
            
            for(Id parentScrId : parentScrToScrMap.keySet()) {
                List<reduivy__Study_Scoring_Criteria__c> childrenScrList = parentScrToScrMap.get(parentScrId);

                for(reduivy__Study_Scoring_Criteria__c childScr : childrenScrList) {
                    
                    reduivy__Individual_Score_Detail__c isd = ISD_Helper.createIsd(childScr, isc.Id);
                    
                    String parentKey = isc.Id + '_' + parentScrId;
                    if(!parentIsdToIsdMap.containsKey(parentKey)) {
                        parentIsdToIsdMap.put(parentKey, new List<reduivy__Individual_Score_Detail__c>());
                    }
                    
                    parentIsdToIsdMap.get(parentKey).add(isd);
                }
            }
            
        }

        if(!parentIsdToIsdMap.isEmpty()){
            List<reduivy__Individual_Score_Detail__c> isdListToInsert = new List<reduivy__Individual_Score_Detail__c>();

            for(List<reduivy__Individual_Score_Detail__c> subIsdList : parentIsdToIsdMap.values()) {
                isdListToInsert.addAll(subIsdList);
            }

            //insert all of the isd first
            REDU_Database_UTIL.doInsert(isdListToInsert, iscMap, 'reduivy__Individual_Score__c', false);

            //error might occured when linking requirement, so need to check before updating parent isd
            for(reduivy__Individual_Score__c isc : iscMap.values()) { 
                if(isc.hasErrors()) {
                    return;
                }
            }

            //update the linkage of the child isd to parent isd
            Map<Id, reduivy__Individual_Score_Detail__c> isdMapToUpdate = new Map<Id, reduivy__Individual_Score_Detail__c>();
            for(reduivy__Individual_Score_Detail__c isd : isdListToInsert) {
                String parentKey = isd.reduivy__Individual_Score__c + '_' + isd.reduivy__Study_Scoring_Criteria__c;

                if(parentIsdToIsdMap.containsKey(parentKey)) {
                    for(reduivy__Individual_Score_Detail__c childIsd : parentIsdToIsdMap.get(parentKey)) {
                        isdMapToUpdate.put(childIsd.Id, new reduivy__Individual_Score_Detail__c(
                            Id = childIsd.Id, 
                            reduivy__Parent_Score_Detail__c = isd.Id,
                            reduivy__Individual_Score__c = childIsd.reduivy__Individual_Score__c
                        ));
                    }
                }
            }
            
            if(!isdMapToUpdate.isEmpty()) {
                REDU_Database_UTIL.doUpdate(isdMapToUpdate.values(), iscMap, 'reduivy__Individual_Score__c', false);
            }
        }
    }
}