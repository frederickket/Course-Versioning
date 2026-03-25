/**
 * @author      WDCi (Lean)
 * @date        Aug 2023
 * @group       Wrapper Object
 * @description Aura/Lightning web component response object
 * @changehistory
 * 
 */
public inherited sharing class REDU_LightningResponse {

    /**
     * @description success
     */
    public static final String SUCCESS = 'success';

    /**
     * @descripton fail
     */
    public static final String FAIL = 'fail';

    /**
     * @description Success or failure indicator
     */
    @AuraEnabled
    public Boolean isSuccess{get; set;}

    /**
     * @description Response message
     */
    @AuraEnabled
    public String message{get; set;}
    
    /**
     * @description ResponseData
     */
    @AuraEnabled
    public string responseData{get; set;}

    /**
     * @description Init a lightning response
     * @param isSuccess
     * @param message
     * @param responseData
     */
    public REDU_LightningResponse(Boolean isSuccess, String message, String responseData){
        this.isSuccess = isSuccess;
        this.message = message;
        this.responseData = responseData;
    }

}