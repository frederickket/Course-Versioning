/**
 * @author      WDCi (Sueanne)
 * @date        March 2024
 * @group       Study Pathway
 * @description Study pathway wizard
 * @changehistory
 * ISS-001917 29-03-2024 Sueanne - new class
 */
public with sharing class REDU_StudyPathwayTerm_LCTRL{
    
    /**
     * @description get study pathway terms
     * @param studyPathwayTermId 
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getStudyPathwayTerm(Id studyPathwayTermId){
        reduivy__Study_Pathway_Term__c spt = null;
        try{
            spt = [
                SELECT Id, Name, reduivy__Study_Pathway__c, reduivy__Term_Number__c, reduivy__Recommended_Credits__c
                FROM reduivy__Study_Pathway_Term__c 
                WHERE Id = :studyPathwayTermId
                WITH USER_MODE
                LIMIT 1
            ];

            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(spt));
            return response;

        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description get study pathway unit list
     * @param studyPathwayTermId
     * @param selectedSpoIds selected study plan option id list
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getStudyPathwayUnits(Id studyPathwayTermId, List<Id> selectedSpoIds){
        List<reduivy__Study_Pathway_Unit__c> studyPwUnitList = new List<reduivy__Study_Pathway_Unit__c>();
        List<reduivy__Study_Pathway_Unit__c> spuList = [
            SELECT reduivy__Study_Unit__r.Name, 
            reduivy__Study_Plan_Group__r.Name, 
            reduivy__Applicable_Study_Plan__r.Name,
            reduivy__Applicable_Study_Plan__c, 
            Id, 
            reduivy__Study_Unit__c
            FROM reduivy__Study_Pathway_Unit__c
            WHERE reduivy__Study_Pathway_Term__c = :studyPathwayTermId
            WITH USER_MODE
        ];

        Set<Id> studyUnitIdSet = new Set<Id>();
        for(reduivy__Study_Pathway_Unit__c spu : spuList){ 
            if(spu.reduivy__Applicable_Study_Plan__c == null){ 
                studyPwUnitList.add(spu);

                if(spu.reduivy__Study_Unit__c != null){
                    studyUnitIdSet.add(spu.reduivy__Study_Unit__c);
                }
            }
        }

        if(!selectedSpoIds.isEmpty()){
            for(reduivy__Study_Pathway_Unit__c spu: spuList){
                for(Id spoId: selectedSpoIds){
                    if(spu.reduivy__Study_Unit__c == null && spu.reduivy__Applicable_Study_Plan__c == spoId){
                        studyPwUnitList.add(spu);
                    }
                    
                    if(spu.reduivy__Study_Unit__c != null && spu.reduivy__Applicable_Study_Plan__c == spoId && !studyUnitIdSet.contains(spu.reduivy__Study_Unit__c)){
                        studyPwUnitList.add(spu);
                        studyUnitIdSet.add(spu.reduivy__Study_Unit__c);
                    }
                }
            }
        }
        
        studyPwUnitList.sort();
        REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(studyPwUnitList));
        return response;
    }
}