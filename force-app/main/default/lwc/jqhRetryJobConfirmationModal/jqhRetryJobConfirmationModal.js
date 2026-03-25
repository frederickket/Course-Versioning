/**
 * @Author 		WDCi (XiRouh)
 * @Date 		Jan 2025
 * @group 		Job Queue Framework
 * @Description Retry job quick action
 * @changehistory
 * ISS-002229 27-02-2025 XiRouh - retry job confirmation
 * ISS-002547 11-07-2025 Lean - hide retry all records option
 */
import { api, wire, track } from 'lwc';
import LightningModal from 'lightning/modal';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { customLabels } from 'c/labelLoader';

import ctrlRetryJob from '@salesforce/apex/REDU_JqhRetryJobConfirmationModal_LCTRL.retryJob';

import CONFIRMATION_TEXT from '@salesforce/label/c.Job_Retry_Confirmation_Text';
import CONFIRMATION_TITLE from '@salesforce/label/c.Job_Retry_Confirmation';
import RETRY_FIELD_LABEL from '@salesforce/label/c.Job_Retry_Field';
import RETRY_OPTION_ALL_LABEL from '@salesforce/label/c.Job_Retry_Option_All_Records';
import RETRY_OPTION_ERROR_ONLY_LABEL from '@salesforce/label/c.Job_Retry_Option_Error_Records_Only';

const RETRY_OPTION_ALL = "All Records";
const RETRY_OPTION_ERRORS_ONLY = "Error Records Only";

export default class JqhRetryJobConfirmationModal extends LightningModal {
    @api jobQueueIds;

    //configurable attributes
	@api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;
	
    selectedRetryOption = RETRY_OPTION_ERRORS_ONLY;
	
	//js library module 'lodash', 'stringutil', 'noheadercss', 'moment', 'fullcalendar', 'fcmoment', 'jquery', 'tooltips'
    modules = [];
	
	/**
     * @descripton library loader
     */
    handleLibLoadSuccess(event) {
        this.isScriptLoaded = true;
        this.isInitSuccess = true;
        
    }

    /**
     * @descripton library loader
     */
    handleLibLoadFail(event) {
        this.isScriptLoaded = true;
        this.isInitSuccess = false;
    }
	
    /**
     * @descripton rendered callback
     */
	renderedCallback(){

    }

    /**
     * @descripton connected callback
     */
    connectedCallback(){
        this.consoleLog(this.jobQueueIds);
	}
	
    /**
     * @descripton disconnected callback
     */
	disconnectedCallback() {
		
	}

    /**
     * @description Return confirmation title
     */
    get confirmationTitle() {
        return CONFIRMATION_TITLE;
    }

    /**
     * @description Return confirmation text
     */
    get confirmationText() {
        return CONFIRMATION_TEXT;
    }

    /**
     * @description Return retry field label
     */
    get retryFieldLabel() {
        return RETRY_FIELD_LABEL;
    }

    /**
     * @description Return retry combobox option
     */
    get retryOptions() {
        let options = [
            {
                label: RETRY_OPTION_ERROR_ONLY_LABEL,
                value: RETRY_OPTION_ERRORS_ONLY,
                selected: true
            }
            
            // ISS-002547 we will only allow retry of error records for now
            // {
            //     label: RETRY_OPTION_ALL_LABEL,
            //     value: RETRY_OPTION_ALL
            // }
        ];


        return options;
    }

    /**
     * @description Handle retry combobox onchange
     */
    handleRetryComboboxChange(event) {
        this.selectedRetryOption = event.detail.value;
    }

    /**
     * @description Handle cancel
     */
    handleCancelClick() {
        this.close('cancel');
    }

    /**
     * @description Handle cancel
     */
    async handleConfirmClick() {
        await this.retryJob();
    }

    /**
     * @description Retry job
     */
    async retryJob() {

        this.toggleSpinner(1);

        ctrlRetryJob({
            jobQueueIds: this.jobQueueIds,
            selectedRetryOption: this.selectedRetryOption
        })
        .then(retryResult => {
            this.toggleSpinner(-1);
            promptSuccess(customLabels.SUCCESS_LABEL, retryResult.message);

            this.consoleLog(retryResult, true);

            this.close('submitted');
        })
        .catch(error => {
            promptError(customLabels.ERROR_LABEL, getErrorMessage(error));
            this.toggleSpinner(-1);

            this.close('failed');
        });

    }

    /**
    * @descripton Return cancel label
    */
    get cancelLabel() {
        return customLabels.CANCEL_LABEL;
    }

    /**
     * @descripton Return confirm label
     */
    get confirmLabel() {
        return customLabels.CONFIRM_LABEL;
    }

    /**
    * @description Return loading label
    */
    get loadingLabel() {
        return customLabels.LOADING_LABEL;
    }

    /**
     * @descripton Spinner loading status
     */
	get isLoading(){
        return this.loadedLists === 0 ? false : true;
    }

    /**
     * @descripton Spinner toggler
     */
	toggleSpinner(loadCount){
        this.loadedLists += loadCount;

        if(this.loadedLists <= 0){
            this.loadedLists = 0;
        }
    }
	
    /**
     * @descripton Console log for debugging
     */
	consoleLog(anything, isJson){
        logInfo('JqhRetryJobConfirmationModal', anything, this.enableDebugMode, isJson);
    }
}