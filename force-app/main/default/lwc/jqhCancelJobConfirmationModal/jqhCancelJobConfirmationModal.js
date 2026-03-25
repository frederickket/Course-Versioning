/**
 * @Author 		WDCi (XiRouh)
 * @Date 		Feb 2025
 * @group 		Job Queue Framework
 * @Description Cancel job confirmation
 * @changehistory
 * ISS-002229 27-02-2025 Xi Rouh - cancel job confirmation
 */
import { api, wire, track } from 'lwc';
import LightningModal from 'lightning/modal';
import { promptInfo, promptError, promptWarning, promptSuccess } from 'c/toasterUtil';
import { getErrorMessage, logInfo, logError } from 'c/loggingUtil';
import { customLabels } from 'c/labelLoader';
import { CloseActionScreenEvent } from 'lightning/actions';

import ctrlCancelJob from '@salesforce/apex/REDU_JqhCancelJobConfirmationModal_LCTRL.cancelJob';

import CONFIRMATION_TEXT from '@salesforce/label/c.Job_Cancel_Confirmation_Text';
import CONFIRMATION_TITLE from '@salesforce/label/c.Job_Cancel_Confirmation';

export default class JqhCancelJobConfirmationModal extends LightningModal {
    @api jobQueueIds;

    //configurable attributes
	@api enableDebugMode = false;
	
	//internal attributes
	isScriptLoaded = false;
	isInitSuccess = false
	loadedLists = 0;

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
     * @description Handle cancel
     */
    handleCancelClick() {
        this.close('cancel');
    }

    /**
     * @description Handle cancel
     */
    async handleConfirmClick() {
        await this.cancelJob();
    }

    /**
     * @description Cancel job
     */
    async cancelJob() {

        this.toggleSpinner(1);

        ctrlCancelJob({
            jobQueueIds: this.jobQueueIds
        })
        .then(cancelResult => {
            this.toggleSpinner(-1);
            promptSuccess(customLabels.SUCCESS_LABEL, cancelResult.message);
            
            this.consoleLog(cancelResult, true);

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
        logInfo('JqhCancelJobConfirmationModal', anything, this.enableDebugMode, isJson);
    }
}