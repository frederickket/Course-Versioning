/**
 * @author      WDCi (Lean)
 * @date        Jan 2024
 * @group       Utility
 * @description Record tile
 * @changehistory
 * ISS-001919 07-08-2024 Lean - new class
 */
public with sharing class REDU_RecordInfoTile_LCTRL {
    
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getRecordAvatarFileUrl(Id recordId, String recordImageFileName){
        try {
            
            Map<Id, String> imageUrlMap = CVS_Helper.getObjectImageUrl(new Set<Id>{recordId}, recordImageFileName);
            String imageUrl;
            if (imageUrlMap.containsKey(recordId)) {
                imageUrl = imageUrlMap.get(recordId);
            }

            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, imageUrl);

        } catch (QueryException qex){

            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp){
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }
}