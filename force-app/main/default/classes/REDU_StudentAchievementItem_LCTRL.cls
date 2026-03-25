/**
 * @author      WDCi (XW)
 * @date        Nov 2025
 * @group       
 * @description 
 * @changehistory
 * ISS-002633 28-11-2025 XW - new class
 */

public with sharing class REDU_StudentAchievementItem_LCTRL {

    /**
     * @description The description
     * @param param The description
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getIndividualRequirementSets(String individualAchievementId) {
        try {
            List<reduivy__Individual_Requirement_Set__c> irsList = new List<reduivy__Individual_Requirement_Set__c>();
            if(String.isNotBlank(individualAchievementId)) {            
                //first, find all the related individualAchievementUnit from individualAchievement
                Set<Id> individualAchievementUnitIdSet = new Set<Id> { individualAchievementId };
                for(reduivy__Individual_Achievement_Unit__c individualAchievementUnit : [
                    SELECT Id 
                    FROM reduivy__Individual_Achievement_Unit__c 
                    WHERE reduivy__Individual_Achievement__c = :individualAchievementId
                    WITH USER_MODE
                ]){
                    individualAchievementUnitIdSet.add(individualAchievementUnit.Id);
                }

                Set<String> irsFields = new Set<String> {
                    'reduivy__Total_Requirement__c',
                    'reduivy__Total_Requirement_Student__c',
                    'reduivy__Total_Reviewed__c',
                    'reduivy__Total_Reviewed_Student__c',
                    'reduivy__Total_Submitted__c',
                    'reduivy__Total_Submitted_Student__c'
                };
                String irsQuery = 'SELECT ' + String.join(irsFields, ',') 
                            + ' FROM ' + IRS_Helper.getApiName()
                            + ' WHERE reduivy__Individual_Achievement__c = :individualAchievementId'
                            + ' OR reduivy__Individual_Achievement_Unit__c IN :individualAchievementUnitIdSet';
                Map<String, Object> irsBindMap = new Map<String, Object> {
                    'individualAchievementUnitIdSet' => individualAchievementUnitIdSet,
                    'individualAchievementId' => individualAchievementId
                };

                for(reduivy__Individual_Requirement_Set__c irs : (List<reduivy__Individual_Requirement_Set__c>) Database.queryWithBinds(irsQuery, irsBindMap, AccessLevel.USER_MODE)) {
                    irsList.add(irs);
                }
            }
            return new REDU_LightningResponse(true, 'success', JSON.serialize(irsList));

        } catch (QueryException qex) {
            REDU_Logging_UTIL.debug(qex);

            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, false);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);

            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }
}
