/**
 * @Author 		WDCi (Lean)
 * @Date 		Jan 2025
 * @group 		Job Queue Framework
 * @Description Retry job quick action
 * @changehistory
 * ISS-002219 06-01-2025 Lean - retry job quick action
 * ISS-002547 11-07-2025 Lean - hide retry all records option and remove record redirection as we won't have the id anymore
 */
import { LightningElement, api, wire, track } from 'lwc';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { customLabels } from 'c/labelLoader';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';

import ctrlRetryJob from '@salesforce/apex/REDU_JqhRetryJob_LCTRL.retryJob';

import CONFIRMATION_TEXT from '@salesforce/label/c.Job_Retry_Confirmation_Text';
import CONFIRMATION_TITLE from '@salesforce/label/c.Job_Retry_Confirmation';
import RETRY_FIELD_LABEL from '@salesforce/label/c.Job_Retry_Field';
import RETRY_OPTION_ALL_LABEL from '@salesforce/label/c.Job_Retry_Option_All_Records';
import RETRY_OPTION_ERROR_ONLY_LABEL from '@salesforce/label/c.Job_Retry_Option_Error_Records_Only';

const RETRY_OPTION_ALL = "All Records";
const RETRY_OPTION_ERRORS_ONLY = "Error Records Only";

export default class JqhRetryJob extends NavigationMixin(LightningElement) {
	
    //LWC quick actions don’t pass in recordId in connectedCallback(), this is official workaround
    _recordId;

    @api
    get recordId() {
        return this._recordId;
    }

    set recordId(recordId) {
        if (recordId !== this._recordId) {
            this._recordId = recordId;
        }
    }

	//configurable attributes
	@api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;
	
    selectedRetryOption = RETRY_OPTION_ERRORS_ONLY;

	//labels
	label = customLabels;
	
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
        this.consoleLog(this._recordId);
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
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    /**
     * @description Handle cancel
     */
    async handleConfirmClick() {
        await this.retryJob();
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    /**
     * @description Retry job
     */
    async retryJob() {

        this.toggleSpinner(1);

        ctrlRetryJob({
            jobQueueId: this._recordId,
            selectedRetryOption: this.selectedRetryOption
        })
        .then(retryResult => {
            this.toggleSpinner(-1);
            promptSuccess(this.label.SUCCESS_LABEL, retryResult.message);

            this.consoleLog(retryResult, true);
            
        })
        .catch(error => {
            promptError(this.label.ERROR_LABEL, getErrorMessage(error));
            this.toggleSpinner(-1);
        });

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
        logInfo('JqhRetryJob', anything, this.enableDebugMode, isJson);
    }
	
}