/**
 * @author      WDCi (XW)
 * @date        Apr 2024
 * @group       Wrapper Object
 * @description Rest Response object
 * @changehistory
 * ISS-002352 18-04-2025 XW - create new class
 */

global inherited sharing class REDU_RestResponse {

    /**
     * @description status - success
     */
    public static final String SUCCESS = 'success';

    /**
     * @descripton status - fail
     */
    public static final String FAIL = 'fail';

    /**
     * @description status
     */
    public String status {get; set;}

    /**
     * @description Success or failure indicator
     */
	public Boolean isSuccess {get; set;}

    /**
     * @description Response message
     */
	public String message {get; set;}

    /**
     * @description Record Id of the target record
     */
	public String recordId {get; set;}

    /**
     * @description init a rest response
     * @param  status
     * @param  isSuccess
     * @param  message
     * @param  recordId
     */
    public REDU_RestResponse(String status, Boolean isSuccess, String message, String recordId){
        this.status = status;
        this.isSuccess = isSuccess;
        this.message = message;
        this.recordId = recordId;
    }

    public REDU_RestResponse(){

    }
}