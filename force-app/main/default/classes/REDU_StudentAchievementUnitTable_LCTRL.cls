/**
 * @author      WDCi (XW)
 * @date        Dec 2025
 * @group       Student Achievement
 * @description 
 * @changehistory
 * ISS-002633 08-12-2025 XW - new class
 */

public with sharing class REDU_StudentAchievementUnitTable_LCTRL {
    
    static final Map<String, String> REVIEW_STATUS_TYPE_MAP = IRQ_Helper.getReviewStatusTypeMap();
    static final Map<String, String> SUBMISSION_STATUS_TYPE_MAP = IRQ_Helper.getSubmissionStatusTypeMap();
    
    /**
     * @description The description
     * @param param The description
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getIndividualAchievementUnits(String individualAchievementId, String unitTableFields, String language){

        try {
            Map<String, Object> responseData = new Map<String, Object>();

            if(String.isNotBlank(individualAchievementId)) {
                
                Set<String> individualAchievementUnitFields = new Set<String>{'Id'};
                
                String individualAchievementUnitQuery = 'SELECT ' + String.join(individualAchievementUnitFields, ', ')
                            + ' FROM ' + IAU_Helper.getApiName()
                            + ' WHERE reduivy__Individual_Achievement__c = :individualAchievementId';

                Map<String, Object> individualAchievementUnitBindMap = new Map<String, Object>{
                    'individualAchievementId' => individualAchievementId
                };

                Set<Id> individualAchievementUnitIdSet = new Set<Id>();

                for(reduivy__Individual_Achievement_Unit__c individualAchievementUnit : (List<reduivy__Individual_Achievement_Unit__c>) Database.queryWithBinds(individualAchievementUnitQuery, individualAchievementUnitBindMap, AccessLevel.USER_MODE))  {
                    individualAchievementUnitIdSet.add(individualAchievementUnit.Id);
                }

                responseData.put('individualAchievementUnitIdList', individualAchievementUnitIdSet);
                responseData.put(ORG_Helper.IS_COMMUNITY_PARAM, ORG_Helper.isCommunity());
                responseData.put(ORG_Helper.SITE_PATH_PARAM, ORG_Helper.getCurrentCommunitySitePath());
                responseData.put('unitTableFields', getUnitTableFieldsInfo(unitTableFields));
            }
            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(responseData));

        } catch (QueryException qex) {
            REDU_Logging_UTIL.debug(qex);

            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, false);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);

            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }

    
    public static List<REDU_DynamicFieldValue_OBJ> getUnitTableFieldsInfo(String unitTableFields) {
        List<REDU_DynamicFieldValue_OBJ> results = new List<REDU_DynamicFieldValue_OBJ>();
        if(String.isNotBlank(unitTableFields)) {
            Map<String, Schema.DescribeFieldResult> dfrMap = REDU_Metadata_UTIL.describeSObjectFields(IAU_Helper.getApiName(), unitTableFields.split(REDU_List_UTIL.DELIMITER));
            for(String fieldName : dfrMap.keySet()) {
                Schema.DescribeFieldResult dfr = dfrMap.get(fieldName);
                results.add(new REDU_DynamicFieldValue_OBJ(dfr, null, null, false));
            }
            
        }

        return results;
    }

    

    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getIndividualAchievementUnitVerificationStatusesInfo(){
        try{
            Map<String, Object> responseData = new Map<String, Object> {
                'lockingMode' => new Map<String, Object> {
                    IAU_Helper.VERIFICATION_STATUS_LOCKING_MODE_LOCKED => IAU_Helper.getLockedVerificationStatuses(),
                    IAU_Helper.VERIFICATION_STATUS_LOCKING_MODE_UNLOCKED => IAU_Helper.getUnlockedVerificationStatuses()
                },
                'verificationStatusType' => new Map<String, Object> {
                    IAU_Helper.VERIFICATION_STATUS_TYPE_OPEN => IAU_Helper.getOpenVerificationStatuses(),
                    IAU_Helper.VERIFICATION_STATUS_TYPE_SUBMITTED => IAU_Helper.getSubmittedVerificationStatuses(),
                    IAU_Helper.VERIFICATION_STATUS_TYPE_REVIEW => IAU_Helper.getReviewVerificationStatuses(),
                    IAU_Helper.VERIFICATION_STATUS_TYPE_VERIFIED => IAU_Helper.getVerifiedVerificationStatuses(),
                    IAU_Helper.VERIFICATION_STATUS_TYPE_REJECTED => IAU_Helper.getRejectedVerificationStatuses(),
                    IAU_Helper.VERIFICATION_STATUS_TYPE_CANCELLED => IAU_Helper.getCancelledVerificationStatuses()
                },
                'verificationStatusBadgeType' => IAU_Helper.getVerificationStatusesBadgeType()
            };
            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(responseData));
        
        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);

            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }


    }


}
