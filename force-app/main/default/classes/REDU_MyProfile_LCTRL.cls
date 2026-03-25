/**
 * @Author 		WDCi (vtan)
 * @Date 		Oct 2024
 * @group 		Utility
 * @Description My profile tile
 * @changehistory
 * ISS-002151 25-10-2024 vtan - new tile
 */

public with sharing class REDU_MyProfile_LCTRL {

    /**
     * @description Get current user record with contact
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getUser(){

        try {
            User currentUser = USR_Helper.getCurrentUserInfo(UserInfo.getUserId());

            REDU_LightningResponse response = new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(currentUser));
            
            return response;

        } catch (QueryException qex){

            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);

        } catch (Exception exp){
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }
}