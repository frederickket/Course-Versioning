/**
 * @author      WDCi (Lean)
 * @date        Mar 2025
 * @group       Util
 * @description Toast utility
 * @changehistory
 * ISS-002284 03-05-2025 Lean - new class
 */
public with sharing class REDU_Toaster_LCTRL {
    
    /**
     * @description Return toast config by for type
     * @return REDU_LightningResponse
     */
    @AuraEnabled(cacheable=true)
    public static REDU_LightningResponse getToasterConfigs(){

        try {
            return new REDU_LightningResponse(true, REDU_LightningResponse.SUCCESS, JSON.serialize(REDU_Toast_UTIL.getToastConfigsByForType()));

        } catch (QueryException qex) {
            String errorMsg = REDU_ObjectSecurity_UTIL.handleQueryException(qex, true);
            throw REDU_Exception_UTIL.auraException(errorMsg);
    
        } catch (Exception exp) {
            REDU_Logging_UTIL.debug(exp);
            throw REDU_Exception_UTIL.auraException(exp.getMessage());
        }
    }
}