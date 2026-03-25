/**
 * @author      WDCi (XW)
 * @date        Jan 2026
 * @group       Student Achievement
 * @description 
 * @changehistory
 * ISS-002633 15-01-2026 XW - new class
 */

public with sharing class REDU_StudentAchievementSubmit_LCTRL {

    static List<String> IAC_SUBMITTED_STATUSES = IAC_Helper.getSubmittedVerificationStatuses();
    static List<String> IAU_SUBMITTED_STATUSES = IAU_Helper.getSubmittedVerificationStatuses();
    
    /**
     * @description update the individual achievement and related individual achievement unit to submitted
     * @param  individualAchievementId individualAchievementId individual achievement
     * @return       REDU_LightningResponse
     */
    @AuraEnabled
    public static REDU_LightningResponse updateIndividualAchievementIndividualAchievementUnitToSubmitted(String individualAchievementId){
    
        Savepoint sp = Database.setSavePoint();    
        try { 
            
            Set<Id> updatedIdSet = new Set<Id>();
            if(String.isNotBlank(individualAchievementId)) {
                
                reduivy__Individual_Achievement__c targetIndividualAchievement;
                List<reduivy__Individual_Achievement_Unit__c> individualAchievementUnitList = new List<reduivy__Individual_Achievement_Unit__c>();
                for(reduivy__Individual_Achievement__c individualAchievement : [SELECT Id, reduivy__Verification_Status__c,
                    (
                        SELECT Id
                        FROM reduivy__Individual_Achievement_Units__r
                        WHERE reduivy__Verification_Status__c NOT IN :IAU_SUBMITTED_STATUSES
                    )
                    FROM reduivy__Individual_Achievement__c
                    WHERE Id = :individualAchievementId
                    WITH USER_MODE
                ]) {
                    targetIndividualAchievement = individualAchievement;
                    for(reduivy__Individual_Achievement_Unit__c individualAchievementUnit : individualAchievement.reduivy__Individual_Achievement_Units__r) {
                        individualAchievementUnitList.add(individualAchievementUnit);
                    }
                }

                if(targetIndividualAchievement != null) {
                    reduivy__Individual_Achievement__c updateIndividualAchievement = new reduivy__Individual_Achievement__c(
                        Id = individualAchievementId, 
                        reduivy__Verification_Status__c = IAC_SUBMITTED_STATUSES[0],
                        reduivy__Submission_Date__c = System.today()
                    );

                    List<reduivy__Individual_Achievement__c> updateIndividualAchievementList = new List<reduivy__Individual_Achievement__c>{ updateIndividualAchievement };

                    REDU_Database_UTIL.doUpdate(updateIndividualAchievementList);
                    updatedIdSet.add(individualAchievementId);
                }

                if(!individualAchievementUnitList.isEmpty()) {
                    List<reduivy__Individual_Achievement_Unit__c> updateIndividualAchievementUnitList = new List<reduivy__Individual_Achievement_Unit__c>();
                    for(reduivy__Individual_Achievement_Unit__c individualAchievementUnit : individualAchievementUnitList) {
                        updateIndividualAchievementUnitList.add(new reduivy__Individual_Achievement_Unit__c(
                            Id = individualAchievementUnit.Id, 
                            reduivy__Verification_Status__c = IAU_SUBMITTED_STATUSES[0]
                        ));
                        updatedIdSet.add(individualAchievementUnit.Id);
                    }

                    REDU_Database_UTIL.doUpdate(updateIndividualAchievementUnitList);
                }
            }
            

            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(updatedIdSet));
            
        } catch (QueryException qex) {
            Database.rollback(sp);

            REDU_Logging_UTIL.debug(qex);

            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, false);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            Database.rollback(sp);
            
            REDU_Logging_UTIL.debug(exp);
            
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    /**
     * @description  get the children individual achievement units
     * @param  individualAchievementId            individual achievement id
     * @param  additionalFields additional individualAchievement fields
     * @return                  REDU_LightningResponse
     */
    @AuraEnabled(cacheable = true)
    public static REDU_LightningResponse getIndividualAchievementUnits(String individualAchievementId, List<String> additionalFields){
        try {
            List<reduivy__Individual_Achievement_Unit__c> individualAchievementUnitList = new  List<reduivy__Individual_Achievement_Unit__c>();
            
            if(String.isNotBlank(individualAchievementId)) {
                Set<String> individualAchievementUnitFields = new Set<String> {'Id', 'reduivy__Agreement_Recognition_Unit__c'};
                if(additionalFields != null && !additionalFields.isEmpty()) {
                    individualAchievementUnitFields.addAll(additionalFields);
                }
                
                String individualAchievementUnitQuery = 'SELECT ' + String.join(individualAchievementUnitFields, ', ') 
                            + ' FROM ' + IAU_Helper.getApiName()
                            + ' WHERE reduivy__Individual_Achievement__c = :individualAchievementId';

                Map<String, Object> bindMap = new Map<String, Object> {
                    'individualAchievementId' => individualAchievementId
                };

                for(reduivy__Individual_Achievement_Unit__c individualAchievementUnit : (List<reduivy__Individual_Achievement_Unit__c>) Database.queryWithBinds(individualAchievementUnitQuery, bindMap, AccessLevel.USER_MODE)) {
                    individualAchievementUnitList.add(individualAchievementUnit);
                }

            }
            return new REDU_LightningResponse(true, 'success', JSON.serialize(individualAchievementUnitList));

            
        } catch (QueryException qex) {

            REDU_Logging_UTIL.debug(qex);

            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, false);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


}
